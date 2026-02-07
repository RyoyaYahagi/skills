# API設計パターン

## Server Actions（推奨）

Next.js 14+のServer Actionsを使用したAPI設計。

### 基本構成

```
app/
├── actions/
│   ├── user.ts
│   ├── post.ts
│   └── index.ts
└── ...
```

### Server Action定義

```typescript
// app/actions/user.ts
'use server';

import { db } from '@/lib/db';
import { users } from '@/lib/db/schema';
import { auth } from '@clerk/nextjs/server';
import { eq } from 'drizzle-orm';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

// 入力バリデーション
const updateUserSchema = z.object({
  name: z.string().min(1).max(100),
});

export async function updateUser(formData: FormData) {
  const { userId } = await auth();
  if (!userId) throw new Error('Unauthorized');

  const parsed = updateUserSchema.safeParse({
    name: formData.get('name'),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten() };
  }

  await db.update(users)
    .set({ name: parsed.data.name })
    .where(eq(users.clerkId, userId));

  revalidatePath('/profile');
  return { success: true };
}
```

### クライアントでの使用

```typescript
// app/profile/page.tsx
import { updateUser } from '@/app/actions/user';

export default function ProfilePage() {
  return (
    <form action={updateUser}>
      <input name="name" required />
      <button type="submit">更新</button>
    </form>
  );
}
```

### useActionState（フィードバック付き）

```typescript
'use client';

import { useActionState } from 'react';
import { updateUser } from '@/app/actions/user';

export function ProfileForm() {
  const [state, action, pending] = useActionState(updateUser, null);

  return (
    <form action={action}>
      <input name="name" disabled={pending} />
      <button disabled={pending}>
        {pending ? '保存中...' : '保存'}
      </button>
      {state?.error && <p className="error">{state.error}</p>}
    </form>
  );
}
```

---

## tRPC（型安全API）

### セットアップ

```bash
npm install @trpc/server @trpc/client @trpc/react-query @trpc/next @tanstack/react-query zod
```

### サーバー設定

```typescript
// lib/trpc/init.ts
import { initTRPC, TRPCError } from '@trpc/server';
import { auth } from '@clerk/nextjs/server';
import superjson from 'superjson';

export const createTRPCContext = async () => {
  const { userId } = await auth();
  return { userId };
};

const t = initTRPC.context<typeof createTRPCContext>().create({
  transformer: superjson,
});

export const router = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }
  return next({ ctx: { userId: ctx.userId } });
});
```

### ルーター定義

```typescript
// lib/trpc/routers/user.ts
import { z } from 'zod';
import { router, protectedProcedure } from '../init';
import { db } from '@/lib/db';
import { users } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';

export const userRouter = router({
  getMe: protectedProcedure.query(async ({ ctx }) => {
    return db.query.users.findFirst({
      where: eq(users.clerkId, ctx.userId),
    });
  }),

  update: protectedProcedure
    .input(z.object({ name: z.string().min(1) }))
    .mutation(async ({ ctx, input }) => {
      return db.update(users)
        .set({ name: input.name })
        .where(eq(users.clerkId, ctx.userId))
        .returning();
    }),
});
```

### APIハンドラ

```typescript
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { appRouter } from '@/lib/trpc/routers';
import { createTRPCContext } from '@/lib/trpc/init';

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext: createTRPCContext,
  });

export { handler as GET, handler as POST };
```

### クライアント設定

```typescript
// lib/trpc/client.ts
'use client';

import { createTRPCReact } from '@trpc/react-query';
import type { AppRouter } from './routers';

export const trpc = createTRPCReact<AppRouter>();
```

### クライアントでの使用

```typescript
'use client';

import { trpc } from '@/lib/trpc/client';

export function Profile() {
  const { data: user, isLoading } = trpc.user.getMe.useQuery();
  const updateMutation = trpc.user.update.useMutation();

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <p>{user?.name}</p>
      <button onClick={() => updateMutation.mutate({ name: 'New Name' })}>
        更新
      </button>
    </div>
  );
}
```

---

## 使い分け

| 方式               | 適したケース                                       |
| ------------------ | -------------------------------------------------- |
| **Server Actions** | シンプルなCRUD、フォーム処理、少ないエンドポイント |
| **tRPC**           | 複雑なAPI、型安全重視、多数のエンドポイント        |
