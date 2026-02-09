# GitHub Actions Templates for iOS

## PR検証ワークフロー（基本）

```yaml
name: iOS CI

on:
  pull_request:
    branches: [main, develop]
    paths:
      - '**.swift'
      - '**.xib'
      - '**.storyboard'
      - 'Package.swift'
      - 'Podfile'
      - '.github/workflows/ios-ci.yml'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    runs-on: macos-14
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Show Xcode version
        run: xcodebuild -version

      # SPM cache (SPM使用時)
      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: |
            ~/Library/Caches/org.swift.swiftpm
            .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: |
            ${{ runner.os }}-spm-

      - name: Build
        run: |
          xcodebuild build-for-testing \
            -scheme "<SCHEME>" \
            -destination "platform=iOS Simulator,name=iPhone 17" \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO

      - name: Test
        run: |
          xcodebuild test-without-building \
            -scheme "<SCHEME>" \
            -destination "platform=iOS Simulator,name=iPhone 17" \
            -resultBundlePath TestResults.xcresult

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults.xcresult
```

## PR検証 + SwiftLint

```yaml
name: iOS CI with Lint

on:
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  swiftlint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: SwiftLint
        run: |
          if command -v swiftlint &> /dev/null; then
            swiftlint lint --strict --reporter github-actions-logging
          else
            brew install swiftlint
            swiftlint lint --strict --reporter github-actions-logging
          fi

  build-and-test:
    runs-on: macos-14
    needs: swiftlint
    timeout-minutes: 30
    steps:
      # ... (上記の build-and-test と同じ)
```

## CocoaPods プロジェクト用

```yaml
# CocoaPods依存がある場合のキャッシュ設定
- name: Cache CocoaPods
  uses: actions/cache@v4
  with:
    path: Pods
    key: ${{ runner.os }}-pods-${{ hashFiles('**/Podfile.lock') }}
    restore-keys: |
      ${{ runner.os }}-pods-

- name: Install CocoaPods
  run: |
    if [ -f "Podfile" ]; then
      pod install --repo-update
    fi

- name: Build
  run: |
    xcodebuild build-for-testing \
      -workspace "<PROJECT>.xcworkspace" \
      -scheme "<SCHEME>" \
      -destination "platform=iOS Simulator,name=iPhone 17" \
      CODE_SIGNING_ALLOWED=NO
```

## リリースワークフロー（Fastlane連携）

```yaml
name: iOS Release

on:
  workflow_dispatch:
    inputs:
      lane:
        description: 'Fastlane lane to run'
        required: true
        default: 'beta'
        type: choice
        options:
          - beta
          - release

jobs:
  release:
    runs-on: macos-14
    timeout-minutes: 60

    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Install Fastlane
        run: |
          if [ -f "Gemfile" ]; then
            bundle install
          else
            gem install fastlane
          fi

      - name: Run Fastlane
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: |
          if [ -f "Gemfile" ]; then
            bundle exec fastlane ios ${{ inputs.lane }}
          else
            fastlane ios ${{ inputs.lane }}
          fi
```

## Discord通知付き

```yaml
# ジョブ末尾に追加
- name: Notify Discord on Success
  if: success()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK_URL }}
    status: success
    title: "iOS CI passed"
    description: |
      ✅ ビルド成功
      • Branch: `${{ github.ref_name }}`
      • Commit: `${{ github.sha }}`
    url: ${{ github.event.pull_request.html_url }}

- name: Notify Discord on Failure
  if: failure()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK_URL }}
    status: failure
    title: "iOS CI failed"
    description: |
      ❌ ビルド失敗
      • Branch: `${{ github.ref_name }}`
    url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

## 変数置換リスト

| プレースホルダー | 説明                                 |
| ---------------- | ------------------------------------ |
| `<SCHEME>`       | Xcodeスキーム名                      |
| `<PROJECT>`      | プロジェクト名（.xcworkspace使用時） |

> [!IMPORTANT]
> **シミュレーターのデバイス名について**
> 
> テンプレート内の `iPhone 17` は **常にその時点で利用可能な最新モデルに置き換えてください。**
> 利用可能なシミュレーターは `xcrun simctl list devices available` で確認できます。
