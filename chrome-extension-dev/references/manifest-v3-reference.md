# Manifest V3 リファレンス

manifest.json の全フィールド解説。

## 必須フィールド

| フィールド         | 値                  | 説明                       |
| ------------------ | ------------------- | -------------------------- |
| `manifest_version` | `3`                 | 必ず3を指定                |
| `name`             | string (45文字以内) | 拡張機能名                 |
| `version`          | string              | バージョン（`1.0.0` 形式） |

## 推奨フィールド

| フィールド    | 説明                          |
| ------------- | ----------------------------- |
| `description` | 132文字以内の説明             |
| `icons`       | 16, 48, 128px の PNG アイコン |
| `action`      | ツールバーボタンの設定        |

## action

```json
{
  "action": {
    "default_popup": "popup.html",
    "default_icon": { "16": "icon16.png", "48": "icon48.png", "128": "icon128.png" },
    "default_title": "ツールチップテキスト"
  }
}
```

- `default_popup` を省略 → `chrome.action.onClicked` が発火
- `default_popup` を指定 → クリックでPopup表示（onClickedは発火しない）

## background

```json
{
  "background": {
    "service_worker": "background.js",
    "type": "module"
  }
}
```

- `type: "module"` で ES Modules（`import`/`export`）が使用可能

## content_scripts

```json
{
  "content_scripts": [
    {
      "matches": ["https://example.com/*"],
      "exclude_matches": ["https://example.com/admin/*"],
      "js": ["content.js"],
      "css": ["content.css"],
      "run_at": "document_idle",
      "all_frames": false,
      "match_about_blank": false
    }
  ]
}
```

### run_at の値

| 値               | タイミング                          |
| ---------------- | ----------------------------------- |
| `document_idle`  | DOM構築完了後（デフォルト、推奨）   |
| `document_end`   | DOM構築直後、サブリソース読み込み前 |
| `document_start` | CSS適用後、DOM/スクリプト実行前     |

### match patterns

| パターン                     | 意味                        |
| ---------------------------- | --------------------------- |
| `<all_urls>`                 | 全URL（非推奨）             |
| `https://*.example.com/*`    | example.comの全サブドメイン |
| `https://example.com/path/*` | 特定パス以下                |
| `*://example.com/*`          | HTTP/HTTPS両方              |

## permissions 一覧

### 一般的な権限

| 権限             | 説明                           | 使用例                           |
| ---------------- | ------------------------------ | -------------------------------- |
| `activeTab`      | アクティブタブへの一時アクセス | ボタンクリック時にページ内容取得 |
| `alarms`         | スケジュール実行               | 定期的なデータ取得               |
| `bookmarks`      | ブックマーク操作               | ブックマーク管理ツール           |
| `clipboardRead`  | クリップボード読取             | ペースト機能                     |
| `clipboardWrite` | クリップボード書込             | コピー機能                       |
| `contextMenus`   | 右クリックメニュー             | カスタムメニュー追加             |
| `cookies`        | Cookie操作                     | 認証管理                         |
| `downloads`      | ダウンロード操作               | ファイル保存                     |
| `history`        | 履歴アクセス                   | 履歴検索                         |
| `identity`       | OAuth認証                      | Googleログイン                   |
| `notifications`  | 通知表示                       | アラート通知                     |
| `offscreen`      | オフスクリーンDOM              | HTML解析                         |
| `scripting`      | スクリプト注入                 | 動的コンテンツスクリプト         |
| `sidePanel`      | サイドパネル                   | サイドパネルUI                   |
| `storage`        | データ保存                     | 設定・状態の永続化               |
| `tabs`           | タブ情報取得                   | URL/タイトルアクセス             |
| `tabGroups`      | タブグループ操作               | タブ整理ツール                   |
| `webNavigation`  | ナビゲーション監視             | ページ遷移追跡                   |
| `webRequest`     | ネットワーク監視               | リクエスト解析                   |

## web_accessible_resources

Content Script からアクセス可能なリソースを宣言:

```json
{
  "web_accessible_resources": [
    {
      "resources": ["images/*.png", "scripts/inject.js"],
      "matches": ["https://example.com/*"]
    }
  ]
}
```

## side_panel

```json
{
  "side_panel": {
    "default_path": "sidepanel.html"
  }
}
```

## options_page / options_ui

```json
{
  "options_ui": {
    "page": "options.html",
    "open_in_tab": false
  }
}
```

- `open_in_tab: false` → 埋め込みダイアログ表示
- `open_in_tab: true` → 新しいタブで表示

## content_security_policy

```json
{
  "content_security_policy": {
    "extension_pages": "script-src 'self'; object-src 'self'"
  }
}
```

デフォルトCSPに外部リソースは追加不可（Manifest V3の制約）。

## externally_connectable

他の拡張機能やWebサイトからメッセージ受信を許可:

```json
{
  "externally_connectable": {
    "matches": ["https://example.com/*"]
  }
}
```

## commands

キーボードショートカット:

```json
{
  "commands": {
    "_execute_action": {
      "suggested_key": { "default": "Ctrl+Shift+Y", "mac": "Command+Shift+Y" },
      "description": "拡張機能を開く"
    },
    "custom-action": {
      "suggested_key": { "default": "Ctrl+Shift+U" },
      "description": "カスタムアクション"
    }
  }
}
```

## chrome_url_overrides

新しいタブ等のページを上書き:

```json
{
  "chrome_url_overrides": {
    "newtab": "newtab.html"
  }
}
```

`newtab`, `history`, `bookmarks` が上書き可能。

## devtools_page

DevTools パネルを追加:

```json
{
  "devtools_page": "devtools.html"
}
```
