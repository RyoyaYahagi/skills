# CloudKit Sharing Checklist

## 設定チェック
- `Bundle Identifier`
- `Team`
- `iCloud` Capability
- `CloudKit` container
- `CKSharingSupported`
- `UIBackgroundModes = remote-notification`
- `aps-environment`
- `NSCameraUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- SwiftData の `cloudKitDatabase`

## Apple Developer / Console チェック
- App ID に iCloud が有効か
- 使っている container が一致しているか
- `Development` / `Production` の見間違いがないか
- schema deploy が必要なビルド種別か
- `Fetch Changes` に `cloudkit.zoneshare` が見えるか

## ログで見るポイント
- `SwiftDataError error 1`
- `Record not found`
- `CKError 11`
- `remote notification registration failed`
- `subscription save failed`
- `Share fetched but url is nil`
- `Found share in zone changes`

## 判断メモ
- `share 保存成功 + URL だけ nil`:
  CloudKit URL 発行待ちか、share record ID の取り違え。

- `share 受諾成功 + データが見えない`:
  shared zone ID の保存漏れ、shared DB fetch 漏れ、token 分離不足を疑う。

- `push は入れたのに即時反映しない`:
  silent push 非保証。foreground fetch を残しておく。

- `Console で share が検索できない`:
  システム型は通常クエリで探さず `Fetch Changes` を使う。
