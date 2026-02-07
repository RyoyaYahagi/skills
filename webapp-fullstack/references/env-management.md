# 環境変数管理

## ファイル構成

```
project/
├── .env                  # デフォルト値（gitにコミット可）
├── .env.local            # ローカル開発用シークレット（gitignore）
├── .env.development      # 開発環境
├── .env.production       # 本番環境
└── .env.example          # テンプレート（gitにコミット）
```

## .env.example（テンプレート）

```bash
# Database
DATABASE_URL=

# Clerk Auth
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
CLERK_WEBHOOK_SECRET=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Feature flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
```

## 環境別設定

### 開発環境 (.env.development)

```bash
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_ENABLE_ANALYTICS=false
LOG_LEVEL=debug
```

### 本番環境 (.env.production)

```bash
NEXT_PUBLIC_APP_URL=https://your-app.com
NEXT_PUBLIC_ENABLE_ANALYTICS=true
LOG_LEVEL=error
```

## 型安全な環境変数

### Zodによるバリデーション

```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  // サーバーサイドのみ
  DATABASE_URL: z.string().url(),
  CLERK_SECRET_KEY: z.string().min(1),

  // クライアント公開
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().min(1),

  // オプション
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  CLERK_SECRET_KEY: process.env.CLERK_SECRET_KEY,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  LOG_LEVEL: process.env.LOG_LEVEL,
});
```

### 使用方法

```typescript
import { env } from '@/lib/env';

// 型安全にアクセス
console.log(env.NEXT_PUBLIC_APP_URL);
console.log(env.DATABASE_URL);
```

## T3 Env（推奨）

より堅牢な環境変数管理。

```bash
npm install @t3-oss/env-nextjs zod
```

```typescript
// lib/env.ts
import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    CLERK_SECRET_KEY: z.string().min(1),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().min(1),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    CLERK_SECRET_KEY: process.env.CLERK_SECRET_KEY,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  },
});
```

## デプロイ先での設定

### Vercel

```bash
# CLIで設定
vercel env add DATABASE_URL production
vercel env add DATABASE_URL preview
vercel env add DATABASE_URL development

# 一括プル
vercel env pull .env.local
```

### Cloudflare

```bash
# シークレット設定
wrangler secret put DATABASE_URL

# wrangler.tomlで公開変数
[vars]
NEXT_PUBLIC_APP_URL = "https://your-app.pages.dev"
```

## GitHubシークレット（CI/CD用）

```yaml
# .github/workflows/deploy.yml
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  CLERK_SECRET_KEY: ${{ secrets.CLERK_SECRET_KEY }}
```

## 注意点

| ルール                             | 説明                         |
| ---------------------------------- | ---------------------------- |
| `NEXT_PUBLIC_`プレフィックス       | クライアントに公開される     |
| `.env.local`は必ずgitignore        | シークレット漏洩防止         |
| 本番シークレットはデプロイ先で管理 | vercel env / wrangler secret |
