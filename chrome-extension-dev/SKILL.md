---
name: chrome-extension-dev
description: Chrome拡張機能の設計・実装・テスト・リリースを支援するスキル。Manifest V3準拠のプロジェクト構成、主要API活用（Storage/Tabs/Messaging/Content Scripts/Service Worker）、UIパターン（Popup/Side Panel/Options）、セキュリティベストプラクティス、Chrome Web Storeリリースまでカバー。トリガー：「Chrome拡張機能」「Chrome Extension」「ブラウザ拡張」「manifest.json」「Content Script」「Service Worker（拡張機能）」「Popup」「Side Panel」「Chrome API」「chrome.runtime」「chrome.tabs」「Web Store公開」「拡張機能作成」「拡張機能開発」。
---

# Chrome Extension Dev

Manifest V3 準拠の Chrome 拡張機能を設計・実装するためのスキル。

## プロジェクト構造

```
my-extension/
├── manifest.json          # 拡張機能の定義（必須）
├── background.js          # Service Worker（イベント駆動）
├── content.js             # Content Script（Webページに注入）
├── popup/
│   ├── popup.html         # ブラウザアクションのUI
│   ├── popup.js
│   └── popup.css
├── options/
│   ├── options.html       # 設定画面
│   ├── options.js
│   └── options.css
├── sidepanel/
│   ├── sidepanel.html     # サイドパネルUI
│   └── sidepanel.js
├── icons/
│   ├── icon16.png
│   ├── icon48.png
│   └── icon128.png
├── styles/
│   └── common.css
└── lib/                   # 共有ユーティリティ
    └── utils.js
```

## manifest.json テンプレート

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "A brief description of the extension",
  "permissions": [],
  "host_permissions": [],
  "action": {
    "default_popup": "popup/popup.html",
    "default_icon": {
      "16": "icons/icon16.png",
      "48": "icons/icon48.png",
      "128": "icons/icon128.png"
    }
  },
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "css": ["styles/content.css"],
      "run_at": "document_idle"
    }
  ],
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  }
}
```

### permissions の最小化原則

必要最小限の権限のみ宣言する。未使用の権限はレビューリジェクトの原因になる。

| 権限            | 用途                                            |
| --------------- | ----------------------------------------------- |
| `storage`       | データ永続化（ほぼ必須）                        |
| `activeTab`     | 現在のタブのみアクセス（`<all_urls>` より推奨） |
| `tabs`          | タブのURL/タイトル取得                          |
| `scripting`     | プログラムでスクリプト注入                      |
| `alarms`        | 定期実行タスク                                  |
| `notifications` | デスクトップ通知                                |
| `contextMenus`  | 右クリックメニュー                              |
| `sidePanel`     | サイドパネル表示                                |
| `offscreen`     | DOM操作用オフスクリーンドキュメント             |

`host_permissions` は `<all_urls>` を避け、必要なドメインのみ指定:
```json
"host_permissions": ["https://example.com/*", "https://api.example.com/*"]
```

## 主要コンポーネント

### 1. Service Worker（background.js）

イベント駆動で動作。永続的な状態は保持しない（アイドル時に停止される）。

```javascript
// ✅ 正しい: イベントはトップレベルで登録
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    chrome.storage.local.set({ initialized: true });
  }
});

chrome.action.onClicked.addListener((tab) => {
  // Action ボタンクリック時の処理
});

// ❌ 間違い: 非同期でリスナーを登録してはならない
// setTimeout(() => { chrome.runtime.onMessage.addListener(...) }, 0);
```

**Service Worker の注意点:**
- グローバル変数は再起動時にリセットされる → `chrome.storage` を使う
- `setInterval` は使えない → `chrome.alarms` を使う
- DOM アクセスは不可 → `chrome.offscreen` を使う

### 2. Content Script（content.js）

Webページに注入されるスクリプト。ページのDOMにアクセス可能だが、分離されたJSコンテキストで実行。

```javascript
// ページのDOMにアクセス
const title = document.title;
const elements = document.querySelectorAll('.target-class');

// Service Worker に結果を送信
chrome.runtime.sendMessage({
  type: 'PAGE_DATA',
  data: { title, count: elements.length }
});

// Service Worker からのメッセージを受信
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'GET_SELECTION') {
    sendResponse({ text: window.getSelection().toString() });
  }
  return true; // 非同期レスポンスの場合
});
```

**Content Script の制約:**
- chrome.* API は限定的（runtime, storage, i18n のみ）
- ページの JS 変数には直接アクセス不可 → ページスクリプト注入が必要

### 3. メッセージング

```javascript
// --- Popup/Options → Service Worker ---
chrome.runtime.sendMessage({ type: 'ACTION', payload: data }, (response) => {
  console.log('Response:', response);
});

// --- Service Worker → Content Script ---
chrome.tabs.sendMessage(tabId, { type: 'DO_SOMETHING' }, (response) => {
  console.log('Response from content:', response);
});

// --- 長期接続（ストリーミング等） ---
// Content Script 側
const port = chrome.runtime.connect({ name: 'stream' });
port.onMessage.addListener((msg) => { /* ... */ });
port.postMessage({ type: 'START' });

// Service Worker 側
chrome.runtime.onConnect.addListener((port) => {
  if (port.name === 'stream') {
    port.onMessage.addListener((msg) => {
      port.postMessage({ type: 'DATA', data: result });
    });
  }
});
```

### 4. Storage API

```javascript
// ローカルストレージ（デバイス固有、容量大）
await chrome.storage.local.set({ key: value });
const result = await chrome.storage.local.get(['key']);

// 同期ストレージ（Googleアカウント同期、容量小: 100KB）
await chrome.storage.sync.set({ settings: { theme: 'dark' } });

// 変更監視
chrome.storage.onChanged.addListener((changes, area) => {
  for (const [key, { oldValue, newValue }] of Object.entries(changes)) {
    console.log(`${area}:${key} changed from`, oldValue, 'to', newValue);
  }
});
```

## UI パターン

### Popup

```html
<!-- popup/popup.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="popup.css">
</head>
<body>
  <div id="app">
    <h1>Extension Name</h1>
    <button id="action-btn">実行</button>
    <div id="status"></div>
  </div>
  <script src="popup.js"></script>
</body>
</html>
```

**Popup の注意点:**
- `inline script` は CSP で禁止 → 必ず `.js` ファイルで
- Popup を閉じると状態が失われる → `storage` で永続化
- 推奨サイズ: 幅300-400px、高さ最大600px

### Side Panel

```json
// manifest.json に追加
{
  "side_panel": {
    "default_path": "sidepanel/sidepanel.html"
  },
  "permissions": ["sidePanel"]
}
```

```javascript
// Service Worker でサイドパネルを開く
chrome.sidePanel.setOptions({ path: 'sidepanel/sidepanel.html', enabled: true });
chrome.sidePanel.open({ windowId: windowId });
```

### Context Menu

```javascript
// Service Worker で右クリックメニュー追加
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'my-action',
    title: '選択テキストを処理: "%s"',
    contexts: ['selection']
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'my-action') {
    const selectedText = info.selectionText;
    // 処理実行
  }
});
```

## 高度なパターン

### プログラムによるスクリプト注入

```javascript
// manifest.json: "permissions": ["scripting", "activeTab"]
chrome.action.onClicked.addListener(async (tab) => {
  await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: (param) => {
      // ページコンテキストで実行される
      document.body.style.backgroundColor = param;
    },
    args: ['#f0f0f0']
  });
});
```

### Offscreen Document（DOM操作が必要な場合）

```javascript
// Service Worker から Offscreen Document を作成
await chrome.offscreen.createDocument({
  url: 'offscreen.html',
  reasons: ['DOM_PARSER'],
  justification: 'Parse HTML content'
});

// Offscreen Document とメッセージング
chrome.runtime.sendMessage({ target: 'offscreen', type: 'PARSE', html: htmlString });
```

### Alarms（定期実行）

```javascript
// Service Worker
chrome.alarms.create('periodic-task', { periodInMinutes: 30 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'periodic-task') {
    // 30分ごとの処理
  }
});
```

## セキュリティ

1. **CSP 遵守**: インライン JS/CSS は禁止。外部ファイルから読み込む
2. **`eval()` 禁止**: Manifest V3 では使用不可
3. **権限最小化**: 必要な権限のみ宣言
4. **入力検証**: ユーザー入力・ページ内容は必ずサニタイズ
5. **HTTPS 必須**: 外部通信は HTTPS のみ
6. **メッセージ検証**: `onMessage` で送信元とメッセージ形式を検証

```javascript
// ❌ 危険
element.innerHTML = userInput;

// ✅ 安全
element.textContent = userInput;
// または DOMPurify を使用
element.innerHTML = DOMPurify.sanitize(userInput);
```

## 開発ワークフロー

### 1. ローカル開発

```bash
# 1. プロジェクトディレクトリを作成
mkdir my-extension && cd my-extension

# 2. manifest.json と必要なファイルを作成

# 3. Chromeに読み込み
# chrome://extensions/ → 「デベロッパーモード」ON → 「パッケージ化されていない拡張機能を読み込む」
```

### 2. デバッグ

- **Popup**: 右クリック → 「検証」で DevTools
- **Service Worker**: `chrome://extensions/` → 拡張機能の「Service Worker」リンク
- **Content Script**: 対象ページの DevTools → Console → コンテキストを拡張機能に切替
- **`web-devtools-debug` スキルを併用**: リモートデバッグで効率化

### 3. テスト

手動テストに加え、以下を検証:
- 拡張機能のインストール/アンインストール
- Service Worker の再起動後の動作
- 異なるページでの Content Script 動作
- ストレージのデータ整合性
- エラーハンドリングとエッジケース

### 4. アイコン生成

`generate_image` ツールで 128x128 のアイコンを生成し、リサイズ:
```bash
# ImageMagick でリサイズ
convert icon128.png -resize 48x48 icon48.png
convert icon128.png -resize 16x16 icon16.png
```

## Chrome Web Store リリース

### 必要な準備物

| 項目                 | サイズ/形式             | 備考                 |
| -------------------- | ----------------------- | -------------------- |
| ZIPファイル          | -                       | 拡張機能のパッケージ |
| アイコン             | 128x128 PNG             | store listing 用     |
| スクリーンショット   | 1280x800 or 640x400     | 最低1枚、最大5枚     |
| プロモーション画像   | 1400x560                | 任意                 |
| 説明文               | 132文字以内（短い説明） | 必須                 |
| 詳細説明             | -                       | 必須                 |
| プライバシーポリシー | URL                     | 権限使用時は必須     |

### パッケージング

```bash
# 不要ファイルを除外してZIP作成
zip -r extension.zip . \
  -x "*.git*" "*.DS_Store" "node_modules/*" "*.md" "tests/*"
```

### レビュー対応

- 全ての権限に正当な理由を説明できるようにする
- `<all_urls>` は避け、必要なドメインのみ宣言
- リモートコード実行は禁止（外部 JS の動的読み込み不可）
- 単一目的の原則を守る

## 関連スキル

- **web-devtools-debug**: Chrome DevTools MCP でリモートデバッグ
- **webapp-testing**: Playwright での E2E テスト
- **ios-app-icon**: アイコン生成（同様のパターンを適用）

## 詳細リファレンス

- **Manifest V3 全フィールド解説**: [manifest-v3-reference.md](references/manifest-v3-reference.md) 参照
- **Chrome API 逆引き**: [chrome-api-cookbook.md](references/chrome-api-cookbook.md) 参照
