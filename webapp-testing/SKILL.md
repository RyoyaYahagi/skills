---
name: webapp-testing
description: ローカルWebアプリ（localhost）の機能検証とE2EテストをPlaywrightで実行するスキル。サーバー起動管理、再現性のあるシナリオ、検証証跡取得を扱う。単発のブラウザCLI操作は `playwright-cli` を使用。
license: Complete terms in LICENSE.txt
---

# Web Application Testing

ローカルWebアプリの検証は、このスキルを第一選択にする。

## Scope

- 対象: `localhost` / 開発サーバー上の機能検証、E2Eシナリオ、検証証跡取得
- 非対象: 単発の手動的ブラウザ操作（`playwright-cli` を利用）

## Helper Scripts Available

- `scripts/with_server.py` - サーバー起動/終了を含む実行管理（複数サーバー対応）

`--help` を先に実行して使い方を確認し、必要になるまでスクリプト本体は読まない。

## Decision Tree: Choosing Your Approach

```
User task → Is it static HTML?
    ├─ Yes → Read HTML file directly to identify selectors
    │         ├─ Success → Write Playwright script using selectors
    │         └─ Fails/Incomplete → Treat as dynamic (below)
    │
    └─ No (dynamic webapp) → Is the server already running?
        ├─ No → Run: python scripts/with_server.py --help
        │        Then use the helper + write simplified Playwright script
        │
        └─ Yes → Reconnaissance-then-action:
            1. Navigate and wait for networkidle
            2. Take screenshot or inspect DOM
            3. Identify selectors from rendered state
            4. Execute actions with discovered selectors
```

## Example: Using with_server.py

```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py
```

```bash
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_automation.py
```

## Playwright Script Pattern

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')
    # ... test steps ...
    browser.close()
```

## Best Practices

- `networkidle` 待機後にDOM検査を行う
- セレクタは意味的に安定したものを優先する
- 実行ごとに結果を比較できる証跡（ログ/スクリーンショット）を残す

## Coordination

- ブラウザ操作を対話的に進めるだけなら `playwright-cli` を使う。
- コンソール/ネットワーク中心の原因解析は `web-devtools-debug` を使う。
