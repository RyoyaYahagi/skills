# Clerk Authentication

## セットアップ

```bash
npm install @clerk/nextjs
```

## 環境変数

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...

# オプション
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard
```

## ClerkProvider設定

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="ja">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

## ミドルウェア（保護ルート）

```typescript
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhook(.*)',
]);

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
};
```

## 認証コンポーネント

```typescript
// サインイン/サインアップページ
import { SignIn } from '@clerk/nextjs';

export default function SignInPage() {
  return <SignIn />;
}

// ユーザーボタン
import { UserButton } from '@clerk/nextjs';

export function Header() {
  return (
    <header>
      <UserButton afterSignOutUrl="/" />
    </header>
  );
}
```

## サーバーサイドでユーザー取得

```typescript
// Server Component
import { currentUser, auth } from '@clerk/nextjs/server';

export default async function Page() {
  const user = await currentUser();
  const { userId } = await auth();

  if (!userId) {
    return <div>ログインしてください</div>;
  }

  return <div>ようこそ、{user?.firstName}さん</div>;
}
```

## API Route での認証

```typescript
// app/api/protected/route.ts
import { auth } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

export async function GET() {
  const { userId } = await auth();

  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return NextResponse.json({ userId });
}
```

## Webhook設定（ユーザー同期）

```typescript
// app/api/webhook/clerk/route.ts
import { Webhook } from 'svix';
import { headers } from 'next/headers';
import { WebhookEvent } from '@clerk/nextjs/server';

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;
  if (!WEBHOOK_SECRET) throw new Error('Missing CLERK_WEBHOOK_SECRET');

  const headerPayload = await headers();
  const svix_id = headerPayload.get('svix-id');
  const svix_timestamp = headerPayload.get('svix-timestamp');
  const svix_signature = headerPayload.get('svix-signature');

  const body = await req.text();
  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(body, {
      'svix-id': svix_id!,
      'svix-timestamp': svix_timestamp!,
      'svix-signature': svix_signature!,
    }) as WebhookEvent;
  } catch (err) {
    return new Response('Webhook verification failed', { status: 400 });
  }

  if (evt.type === 'user.created') {
    // DBにユーザー作成
    const { id, email_addresses } = evt.data;
    // await db.insert(users).values({ clerkId: id, email: ... });
  }

  return new Response('OK', { status: 200 });
}
```

## Clerkダッシュボード設定

1. Webhook URL: `https://your-app.com/api/webhook/clerk`
2. Events: `user.created`, `user.updated`, `user.deleted`
