---
name: ios-cloudkit-sharing-troubleshoot
description: iOS の CloudKit 共有、CKShare、SwiftData 併用、QR 招待、silent push 同期の不具合を短時間で切り分けて復旧するスキル。Use when family sharing, CloudKit sharing, CKShare.url, cloudkit.zoneshare, iCloud Capability, entitlements, CKSharingSupported, SwiftData + CloudKit, QR 招待/参加, リアルタイム同期, CloudKit Console, or remote notification sync are involved, even if the user only says that shared data does not appear or QR 招待が壊れた.
---

# iOS CloudKit Sharing Troubleshoot

## 使う場面
- CloudKit 家族共有や招待 URL が壊れた
- `CKShare.url` が取れない、QR 生成に失敗する
- QR を読めても共有に参加できない
- 家族共有のデータが別端末へ反映されない
- CloudKit Capability を有効化したら起動しなくなった
- `Record not found` `cloudkit.zoneshare` `CKSharingSupported` `remote-notification` などの語が出た

## 最初に症状を分類する
1. `起動クラッシュ`
- SwiftData / Core Data 初期化時に落ちる、privacy usage description 不足で落ちる、Capability 追加後から起動不能になったケース。

2. `共有作成失敗`
- QR 生成、共有リンク、`CKShare.url`、`cloudkit.zoneshare` 周りの失敗。

3. `共有参加失敗`
- QR 読み取り後に受諾できない、shared zone を見に行けない、shared DB 側へ切り替わらないケース。

4. `同期不達`
- 招待や参加は成功するが、別端末へデータが届かないケース。

症状を混ぜて追わない。同時多発に見えても、先に一番手前の失敗を潰す。

## 進め方
1. ローカル設定を先に確定する
- `Bundle Identifier` `Team` `iCloud container` `entitlements` を一致させる。
- `Info.plist` に `CKSharingSupported` があるか確認する。
- silent push で更新したいなら `UIBackgroundModes` に `remote-notification` が必要。
- QR 読み取りを使うなら `NSCameraUsageDescription` を確認する。
- 画像保存があるなら `NSPhotoLibraryAddUsageDescription` も確認する。

2. SwiftData と CloudKit の責務を分離する
- アプリが CloudKit を `CKContainer` で直接扱うなら、SwiftData 側は `ModelConfiguration(... cloudKitDatabase: .none)` を明示する。
- Capability を有効化しただけで SwiftData の自動 CloudKit 連携が入ることがあるので、ここを曖昧にしない。
- `SwiftDataError error 1` や ModelContainer 初期化失敗は、まずこの設定を疑う。

3. CloudKit Console の見方を間違えない
- Debug 実行なら `Development` 環境を見る。
- Archive/TestFlight/Store 向けなら schema deploy 済みか確認する。
- `cloudkit.share` が通常クエリで見えなくても即断しない。zone share は `Fetch Changes` 側に `cloudkit.zoneshare` として見えることがある。
- `cloudkit.zoneshare` が見えるなら、サーバー側で share 自体は作られている可能性が高い。

4. share record を固定名で決め打ちしない
- `FamilyBookShare` のような固定 `recordName` を前提に fetch し続けると `Record not found` で詰まる。
- 保存結果、zone changes、または actual share record ID から実在する share を発見して使う。
- 一度見つけた share record ID / zone ID / invite URL はキャッシュし、毎回 stale candidate を見に行かない。

5. `CKShare.url` は即時に取れない前提で扱う
- 共有作成成功と招待 URL 発行は同時に揃わないことがある。
- 保存直後の戻り値、share 再取得、短い backoff 付き retry を使う。
- ただし stale candidate の `Record not found` は致命扱いせず、実 share 探索へ進む。
- リトライ回数と待機時間は最小に保ち、URL を取得できたらキャッシュして次回を速くする。

6. 参加側は shared zone を正しく保持する
- `CKShare.Metadata.share.recordID.zoneID` を保存する。
- 参加後の初回 fetch は private DB ではなく shared DB のその zone を読む。
- private/shared の change token は分ける。
- 参加処理後に subscription を再設定する。

7. 準リアルタイム同期の前提を満たす
- `CKRecordZoneSubscription` を private zone と shared zone の両方に張る。
- `shouldSendContentAvailable = true` を設定する。
- アプリ起動時に remote notification 登録を行い、push 受信で差分 fetch する。
- それでも iOS の silent push は配信保証がない。前面復帰時 fetch を保険で残す。
- 「完全リアルタイム」ではなく「push が届けば自動同期、届かなくても foreground で追従」と説明する。

8. ログを握りつぶさない
- `try?` や `nil` 握りつぶしで CloudKit エラーを隠さない。
- 少なくとも以下を出す。
- share record ID / zone ID
- `CKError` の code と localizedDescription
- save/fetch/accept/subscription のどこで失敗したか
- stale candidate を無視したのか、実 share を見つけたのか

## 典型的な失敗パターン
- Capability 追加後に起動不能:
`SwiftData` の自動 CloudKit 連携が入っている可能性が高い。SwiftData の CloudKit を明示的に切る。

- QR 生成だけ失敗:
share 作成そのものではなく `CKShare.url` 取得遅延か stale record fetch を疑う。

- Console で `cloudkit.share` が見えない:
通常クエリではなく `Fetch Changes` で `cloudkit.zoneshare` を確認する。

- Bundle ID が怪しい気がする:
share 保存まで通っているなら、本命は bundle mismatch ではなく share / zone / fetch ロジックの可能性が高い。

- 共有参加後に同期しない:
participant が owner private zone に書いていないか、shared DB ではなく private DB を読んでいないかを確認する。

- 実機では動くがシミュレーターでリアルタイム同期しない:
silent push の挙動差を疑い、最終判断は実機 2 台で行う。

## 出力フォーマット
- 症状の分類
- 原因候補（優先順 3 件まで）
- 確認した設定
- 実施した修正
- 検証結果
- 再発防止

## 読み込む追加資料
- 具体的なチェック項目やログの読み方が必要なら `references/cloudkit-sharing-checklist.md` を読む。

## 非対象
- 純粋な Code Signing / Provisioning だけの問題は `xcode-signing-troubleshoot` を優先。
- Appium や WDA の復旧は `appium-mcp-recovery` を優先。
