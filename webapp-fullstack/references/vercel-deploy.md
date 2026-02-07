# Vercel Deploy

## CLI セットアップ

```bash
npm i -g vercel
vercel login
```

## プロジェクトリンク

```bash
vercel link
```

## デプロイ

```bash
# プレビュー
vercel

# 本番
vercel --prod
```

## GitHub連携（推奨）

1. Vercelダッシュボードでプロジェクトをインポート
2. GitHubリポジトリを選択
3. 自動デプロイが有効化

### 環境変数設定

```bash
# CLIで設定
vercel env add DATABASE_URL production
vercel env add CLERK_SECRET_KEY production

# または vercel.json
```

## vercel.json（オプション）

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["hnd1"],
  "env": {
    "NEXT_PUBLIC_APP_URL": "https://your-app.vercel.app"
  }
}
```

## Edge Functions

```typescript
// app/api/edge-example/route.ts
export const runtime = 'edge';

export async function GET(request: Request) {
  return Response.json({ message: 'Hello from Edge!' });
}
```

## 環境変数の優先順位

1. Vercelダッシュボード（Production/Preview/Development）
2. `.env.local`（ローカル開発）
3. `vercel.json`

## よくある問題

| 問題                   | 解決策                           |
| ---------------------- | -------------------------------- |
| ビルドエラー           | `vercel logs` で確認             |
| 環境変数が読めない     | `NEXT_PUBLIC_`プレフィックス確認 |
| Edge関数でDB接続エラー | Neon Serverless Driver使用       |
