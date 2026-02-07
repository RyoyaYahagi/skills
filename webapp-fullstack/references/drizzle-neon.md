# Drizzle ORM + Neon

## セットアップ

```bash
npm install drizzle-orm @neondatabase/serverless
npm install -D drizzle-kit
```

## 環境変数

```bash
# .env.local
DATABASE_URL=postgresql://user:password@ep-xxx.region.neon.tech/dbname?sslmode=require
```

## DB接続設定

```typescript
// lib/db/index.ts
import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as schema from './schema';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```

### Edge Runtime用（Vercel Edge / Cloudflare Workers）

```typescript
// lib/db/index.ts
import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import * as schema from './schema';

// Edge環境ではHTTP経由で接続
const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```

## スキーマ定義

```typescript
// lib/db/schema.ts
import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  clerkId: text('clerk_id').unique().notNull(),
  email: text('email').notNull(),
  name: text('name'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id).notNull(),
  title: text('title').notNull(),
  content: text('content'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// リレーション定義
import { relations } from 'drizzle-orm';

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  user: one(users, {
    fields: [posts.userId],
    references: [users.id],
  }),
}));
```

## drizzle.config.ts

```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './lib/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

## マイグレーション

```bash
# マイグレーション生成
npx drizzle-kit generate

# マイグレーション適用
npx drizzle-kit migrate

# DBスタジオ（GUI）
npx drizzle-kit studio
```

## CRUD操作

```typescript
import { db } from '@/lib/db';
import { users, posts } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';

// 作成
const newUser = await db.insert(users).values({
  clerkId: 'clerk_xxx',
  email: 'user@example.com',
  name: 'John',
}).returning();

// 読み取り
const user = await db.query.users.findFirst({
  where: eq(users.clerkId, 'clerk_xxx'),
  with: { posts: true },
});

// 更新
await db.update(users)
  .set({ name: 'Jane' })
  .where(eq(users.id, userId));

// 削除
await db.delete(users).where(eq(users.id, userId));
```

## Server Actions での使用

```typescript
// app/actions/user.ts
'use server';

import { db } from '@/lib/db';
import { users } from '@/lib/db/schema';
import { auth } from '@clerk/nextjs/server';
import { eq } from 'drizzle-orm';

export async function getUser() {
  const { userId } = await auth();
  if (!userId) throw new Error('Unauthorized');

  return db.query.users.findFirst({
    where: eq(users.clerkId, userId),
  });
}
```

## package.json scripts

```json
{
  "scripts": {
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "db:push": "drizzle-kit push"
  }
}
```

## よくある問題

| 問題                   | 解決策                               |
| ---------------------- | ------------------------------------ |
| Edge環境で接続エラー   | `@neondatabase/serverless`使用       |
| SSL接続エラー          | `?sslmode=require`をURLに追加        |
| マイグレーションエラー | `DATABASE_URL`が設定されているか確認 |
