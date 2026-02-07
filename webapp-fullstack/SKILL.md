---
name: webapp-fullstack
description: Next.js/Remixフルスタックアプリ開発。Vercel/Cloudflareデプロイ、Clerk認証、Drizzle ORM + Neon DB接続。Webアプリ開発、デプロイ設定、認証設定、DB接続等のキーワードで使用。
---

# Fullstack Web App Development

Next.js/Remixアプリのデプロイ・認証・DB接続を設定するスキル。

## ワークフロー

1. プロジェクト構成を確認（Next.js / Remix / その他）
2. 必要な機能を特定（デプロイ / 認証 / DB）
3. 適切な参照ドキュメントを読み込み設定

## 必須入力

- フレームワーク: Next.js / Remix / その他
- デプロイ先: Vercel / Cloudflare Pages / Cloudflare Workers
- 認証: Clerk / None
- データベース: Neon + Drizzle / None

## 機能別ガイド

| 機能               | 参照ドキュメント                |
| ------------------ | ------------------------------- |
| Vercelデプロイ     | references/vercel-deploy.md     |
| Cloudflareデプロイ | references/cloudflare-deploy.md |
| Clerk認証          | references/clerk-auth.md        |
| Drizzle + Neon     | references/drizzle-neon.md      |
| API設計            | references/api-patterns.md      |
| 環境変数管理       | references/env-management.md    |

## 実装順序（推奨）

1. **DB設定** - Neon接続とDrizzleスキーマ定義
2. **認証** - Clerk統合とミドルウェア設定
3. **デプロイ** - 環境変数設定とデプロイ

## 他スキルとの連携

- **web-artifacts-builder**: 静的HTMLアーティファクト生成
- **webapp-testing**: Playwrightによるe2eテスト

## 環境変数（共通）

```bash
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...

# Neon
DATABASE_URL=postgresql://...

# Vercel/Cloudflare固有は各参照ドキュメント参照
```

## References

- references/vercel-deploy.md
- references/cloudflare-deploy.md
- references/clerk-auth.md
- references/drizzle-neon.md
- references/api-patterns.md
- references/env-management.md
