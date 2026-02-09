---
name: web-devtools-debug
description: WebアプリとChrome拡張機能のデバッグスキル。Chrome DevTools MCPを使ってブラウザをリモートデバッグ。コンソールエラー確認、ネットワーク監視、DOM検査、JavaScript実行、スクリーンショット取得。トリガー：「デバッグ」「コンソールエラー」「ネットワーク確認」「DOM検査」「ブラウザテスト」「Chrome拡張機能デバッグ」「DevTools」「JS実行」「エラー調査」。
---

# Web DevTools Debug

Chrome DevTools MCP を使用してWebアプリ・Chrome拡張機能をリモートデバッグするスキル。

## 前提条件

1. **Chrome DevTools MCP が設定済み** (`mcp_config.json` に `chrome-devtools-mcp` エントリあり)
2. **Chrome をリモートデバッグモードで起動**

## Chromeのリモートデバッグ起動

```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222

# すでにChromeが起動している場合は一度終了してから上記コマンドを実行
```

## 利用可能なMCPツール

Chrome DevTools MCPが提供するツールを活用する:

### 1. ページ操作
- **navigate**: URLに移動
- **click**: 要素をクリック
- **type**: テキスト入力
- **screenshot**: スクリーンショット取得
- **getPageContent**: ページHTML取得

### 2. デバッグ
- **evaluate**: JavaScript実行
- **getConsoleMessages**: コンソールログ取得
- **getNetworkRequests**: ネットワークリクエスト確認

### 3. 検査
- **getElements**: DOM要素検索
- **getStyles**: CSS スタイル取得

## デバッグワークフロー

### Chrome拡張機能デバッグ

1. **拡張機能ページを開く**
   ```
   navigate to: chrome://extensions/
   ```

2. **Service Workerのコンソールログ確認**
   - 拡張機能の「Service Worker」リンクをクリック
   - 別のDevToolsウィンドウが開く
   - コンソールログを確認

3. **Content Scriptのデバッグ**
   ```
   # 対象ページに移動後
   evaluate: console.log(window.kindleDetector) # グローバルオブジェクト確認
   getConsoleMessages # ログ取得
   ```

### Webアプリデバッグ

1. **ページ読み込み確認**
   ```
   navigate to: http://localhost:3000
   screenshot # 初期状態確認
   ```

2. **コンソールエラー確認**
   ```
   getConsoleMessages # エラー一覧取得
   ```

3. **ネットワーク問題調査**
   ```
   getNetworkRequests # 失敗したリクエスト確認
   ```

4. **DOM状態確認**
   ```
   getElements: selector="#app"
   evaluate: document.querySelector('#app').innerHTML
   ```

## 一般的なデバッグパターン

### パターン1: エラー調査

```
1. getConsoleMessages でエラーログ取得
2. エラーメッセージから原因特定
3. evaluate でオブジェクトの状態確認
4. コード修正
5. ページリロード (navigate で同じURLに再移動)
6. 修正確認
```

### パターン2: 要素が見つからない

```
1. screenshot でページ状態確認
2. getPageContent でHTML取得
3. 正しいセレクタを特定
4. getElements で要素の存在確認
```

### パターン3: イベントが発火しない

```
1. evaluate でイベントリスナー確認
   getEventListeners(document.querySelector('button'))
2. click でイベント発火テスト
3. getConsoleMessages でログ確認
```

## Chrome拡張機能特有の問題

### manifest.json エラー
```
navigate to: chrome://extensions/
# エラーバッジがあれば "詳細" をクリック
# エラーメッセージを確認
```

### Content Script が読み込まれない
```
# 対象ページに移動
navigate to: https://example.com
# コンテンツスクリプトのグローバル変数確認
evaluate: typeof window.myContentScript !== 'undefined'
```

### Service Worker エラー
- Service Worker の DevTools は別ウィンドウで開く必要あり
- エラーは `chrome://extensions/` ページに表示される

## 他スキルとの連携

- **webapp-testing**: Playwrightでのe2eテスト（ヘッドレス）
- **code-review**: コード問題のレビュー
- **ios-bug-checker**: iOSアプリのバグチェック（類似パターン適用）

## トラブルシューティング

### MCP接続エラー
1. Chromeがリモートデバッグモードで起動しているか確認
2. ポート9222が使用可能か確認: `lsof -i :9222`
3. Antigravityを再起動

### ツールが見つからない
1. `mcp_config.json` の設定確認
2. Antigravityを再起動してMCPサーバーを再接続
