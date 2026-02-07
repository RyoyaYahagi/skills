# Cloudflare Deploy

## Cloudflare Pages（静的サイト・SSR）

### Wrangler セットアップ

```bash
npm i -g wrangler
wrangler login
```

### Next.js（@cloudflare/next-on-pages）

```bash
npm install @cloudflare/next-on-pages

# next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export', // 静的の場合
};
module.exports = nextConfig;
```

### wrangler.toml

```toml
name = "my-app"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
NEXT_PUBLIC_APP_URL = "https://my-app.pages.dev"

# シークレットはCLIで設定
# wrangler secret put DATABASE_URL
```

### デプロイ

```bash
# ビルド
npx @cloudflare/next-on-pages

# デプロイ
wrangler pages deploy .vercel/output/static
```

### GitHub連携

1. Cloudflareダッシュボード → Pages
2. 「Connect to Git」→ GitHubリポジトリ選択
3. ビルド設定:
   - Framework: Next.js
   - Build command: `npx @cloudflare/next-on-pages`
   - Output directory: `.vercel/output/static`

## Cloudflare Workers（API/フルスタック）

### Hono + Workers

```bash
npm create hono@latest my-api
cd my-api
npm install
```

```typescript
// src/index.ts
import { Hono } from 'hono';

type Bindings = {
  DATABASE_URL: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.get('/api/health', (c) => c.json({ status: 'ok' }));

export default app;
```

### wrangler.toml（Workers）

```toml
name = "my-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
ENVIRONMENT = "production"
```

### デプロイ

```bash
wrangler deploy
```

## 環境変数・シークレット

```bash
# シークレット設定
wrangler secret put DATABASE_URL
wrangler secret put CLERK_SECRET_KEY

# 確認
wrangler secret list
```

## D1データベース（SQLite）

```bash
# DB作成
wrangler d1 create my-db

# wrangler.tomlに追加
[[d1_databases]]
binding = "DB"
database_name = "my-db"
database_id = "xxxxx"
```

## よくある問題

| 問題                  | 解決策                         |
| --------------------- | ------------------------------ |
| Node.js API使用エラー | `nodejs_compat`フラグ追加      |
| Drizzle接続エラー     | Neon Serverless Driver使用     |
| ビルドサイズ超過      | 不要な依存削除、動的インポート |
