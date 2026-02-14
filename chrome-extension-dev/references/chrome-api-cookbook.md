# Chrome API 逆引きクックブック

やりたいことから必要なAPIを引くリファレンス。

## 目次

1. [タブ操作](#タブ操作)
2. [ページ内容の取得・操作](#ページ内容の取得操作)
3. [データ永続化](#データ永続化)
4. [通知・UI](#通知ui)
5. [ネットワーク](#ネットワーク)
6. [認証・ID](#認証id)
7. [ファイル操作](#ファイル操作)
8. [定期実行](#定期実行)
9. [Webページとの通信](#webページとの通信)
10. [デバッグ・開発](#デバッグ開発)

---

## タブ操作

### 現在のタブを取得

```javascript
const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
```

### 新しいタブを開く

```javascript
const tab = await chrome.tabs.create({ url: 'https://example.com' });
```

### タブのURLを変更

```javascript
await chrome.tabs.update(tabId, { url: 'https://example.com' });
```

### 特定URLのタブを検索

```javascript
const tabs = await chrome.tabs.query({ url: 'https://example.com/*' });
```

### タブの読み込み完了を待つ

```javascript
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete') {
    // ページ読み込み完了
  }
});
```

### タブをグループ化

```javascript
// permissions: ["tabGroups"]
const groupId = await chrome.tabs.group({ tabIds: [tab1.id, tab2.id] });
await chrome.tabGroups.update(groupId, { title: 'グループ名', color: 'blue' });
```

---

## ページ内容の取得・操作

### ページのタイトル/URLを取得

```javascript
// permissions: ["tabs"] or "activeTab"
const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
console.log(tab.title, tab.url);
```

### ページにスクリプトを注入して情報取得

```javascript
// permissions: ["scripting", "activeTab"]
const results = await chrome.scripting.executeScript({
  target: { tabId: tab.id },
  func: () => {
    return {
      title: document.title,
      text: document.body.innerText.slice(0, 1000),
      links: Array.from(document.links).map(a => a.href)
    };
  }
});
const pageData = results[0].result;
```

### ページの選択テキストを取得

```javascript
// Content Script 内
const selectedText = window.getSelection().toString();

// または Service Worker から
const results = await chrome.scripting.executeScript({
  target: { tabId: tab.id },
  func: () => window.getSelection().toString()
});
```

### ページにCSSを注入

```javascript
await chrome.scripting.insertCSS({
  target: { tabId: tab.id },
  css: 'body { background-color: #f0f0f0; }'
});
```

### ページのスクリーンショット

```javascript
const dataUrl = await chrome.tabs.captureVisibleTab(null, { format: 'png' });
```

---

## データ永続化

### 設定を保存・読み込み

```javascript
// 保存
await chrome.storage.sync.set({
  settings: { theme: 'dark', fontSize: 14 }
});

// 読み込み（デフォルト値付き）
const { settings } = await chrome.storage.sync.get({
  settings: { theme: 'light', fontSize: 12 }
});
```

### 大量データの保存

```javascript
// storage.local は約 10MB まで（unlimitedStorage で無制限）
// permissions: ["storage", "unlimitedStorage"]
await chrome.storage.local.set({ largeData: bigObject });
```

### セッションストレージ（Service Worker再起動間で保持）

```javascript
// Service Worker の再起動間でデータ保持（メモリ内、10MB制限）
await chrome.storage.session.set({ tempData: value });
```

### データ変更の監視

```javascript
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'sync' && changes.settings) {
    applySettings(changes.settings.newValue);
  }
});
```

---

## 通知・UI

### デスクトップ通知

```javascript
// permissions: ["notifications"]
chrome.notifications.create('notif-id', {
  type: 'basic',
  iconUrl: 'icons/icon128.png',
  title: '通知タイトル',
  message: '通知の内容',
  priority: 2
});

chrome.notifications.onClicked.addListener((notificationId) => {
  // 通知クリック時の処理
});
```

### バッジ（アイコン上の数字）

```javascript
await chrome.action.setBadgeText({ text: '5' });
await chrome.action.setBadgeBackgroundColor({ color: '#FF0000' });
// バッジをクリア
await chrome.action.setBadgeText({ text: '' });
```

### ツールチップ変更

```javascript
await chrome.action.setTitle({ title: '新しいツールチップ' });
```

### アイコン動的変更

```javascript
await chrome.action.setIcon({
  path: { 16: 'icons/active16.png', 48: 'icons/active48.png' }
});
```

---

## ネットワーク

### API リクエスト（fetch）

```javascript
// Service Worker 内で外部APIを呼ぶ
// host_permissions に対象ドメインを追加
const response = await fetch('https://api.example.com/data', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ key: 'value' })
});
const data = await response.json();
```

### ネットワークリクエスト監視

```javascript
// permissions: ["webRequest"], host_permissions: ["<all_urls>"]
chrome.webRequest.onBeforeRequest.addListener(
  (details) => {
    console.log('Request:', details.url);
  },
  { urls: ['https://example.com/*'] }
);
```

### リクエストのブロック/リダイレクト

```javascript
// declarativeNetRequest を使用（Manifest V3推奨）
// permissions: ["declarativeNetRequest"]
chrome.declarativeNetRequest.updateDynamicRules({
  addRules: [{
    id: 1,
    priority: 1,
    action: { type: 'block' },
    condition: { urlFilter: 'ads.example.com', resourceTypes: ['script'] }
  }],
  removeRuleIds: [1]
});
```

---

## 認証・ID

### OAuth2 認証（Google）

```json
// manifest.json
{
  "permissions": ["identity"],
  "oauth2": {
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "scopes": ["https://www.googleapis.com/auth/userinfo.email"]
  }
}
```

```javascript
const token = await chrome.identity.getAuthToken({ interactive: true });
// token を使って Google API を呼ぶ
```

### 外部OAuth（非Google）

```javascript
const redirectUrl = chrome.identity.getRedirectURL();
const authUrl = `https://auth.example.com/authorize?redirect_uri=${redirectUrl}&client_id=...`;
const responseUrl = await chrome.identity.launchWebAuthFlow({
  url: authUrl,
  interactive: true
});
// responseUrl からトークンを抽出
```

---

## ファイル操作

### ファイルをダウンロード

```javascript
// permissions: ["downloads"]
const downloadId = await chrome.downloads.download({
  url: 'https://example.com/file.pdf',
  filename: 'saved-file.pdf',
  saveAs: true  // ダイアログ表示
});
```

### Blobデータをダウンロード

```javascript
// Content Script や Popup 内
const blob = new Blob([content], { type: 'text/plain' });
const url = URL.createObjectURL(blob);
await chrome.downloads.download({ url, filename: 'output.txt' });
URL.revokeObjectURL(url);
```

---

## 定期実行

### 一定間隔で実行

```javascript
// permissions: ["alarms"]
// 最小間隔は1分（開発時は30秒）
chrome.alarms.create('check-updates', { periodInMinutes: 60 });

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'check-updates') {
    await checkForUpdates();
  }
});
```

### 指定時刻に実行

```javascript
const when = new Date();
when.setHours(9, 0, 0, 0);
if (when < Date.now()) when.setDate(when.getDate() + 1);

chrome.alarms.create('morning-task', { when: when.getTime(), periodInMinutes: 1440 });
```

---

## Webページとの通信

### Content Script ↔ Service Worker

```javascript
// Content Script → Service Worker
chrome.runtime.sendMessage({ type: 'DATA', payload: data });

// Service Worker で受信
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'DATA') {
    processData(msg.payload).then(result => sendResponse(result));
    return true; // 非同期レスポンス
  }
});
```

### 外部Webサイトから拡張機能にメッセージ

```json
// manifest.json
{ "externally_connectable": { "matches": ["https://mysite.com/*"] } }
```

```javascript
// Webサイト側
chrome.runtime.sendMessage('EXTENSION_ID', { type: 'HELLO' }, (response) => {
  console.log(response);
});

// 拡張機能側
chrome.runtime.onMessageExternal.addListener((msg, sender, sendResponse) => {
  if (sender.origin === 'https://mysite.com') {
    sendResponse({ status: 'ok' });
  }
});
```

### ページのJSコンテキストにアクセス（Isolated World 回避）

```javascript
// Content Script からページスクリプトを注入
const script = document.createElement('script');
script.src = chrome.runtime.getURL('scripts/inject.js');
document.head.appendChild(script);

// inject.js は web_accessible_resources に宣言が必要
```

---

## デバッグ・開発

### Service Worker のログ確認

```
chrome://extensions/ → 拡張機能の「Service Worker」リンク → Console
```

### Content Script のログ確認

```
対象ページの DevTools → Console → コンテキストセレクタで拡張機能を選択
```

### 拡張機能の再読み込み

```javascript
// 開発中のホットリロード（Service Worker内）
chrome.management.getSelf((self) => {
  chrome.runtime.reload();
});
```

### エラーの確認

```
chrome://extensions/ → 「エラー」ボタン
```
