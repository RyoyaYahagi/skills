# Caching Strategies for iOS CI

GitHub Actionsでのビルド時間短縮のためのキャッシュ戦略。

## Swift Package Manager (SPM)

```yaml
- name: Cache SPM
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/org.swift.swiftpm
      .build
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

**効果**: SPMパッケージのダウンロード時間を削減（通常1-3分 → 数秒）

## CocoaPods

```yaml
- name: Cache CocoaPods
  uses: actions/cache@v4
  with:
    path: Pods
    key: ${{ runner.os }}-pods-${{ hashFiles('**/Podfile.lock') }}
    restore-keys: |
      ${{ runner.os }}-pods-

- name: Install Pods
  run: pod install
```

**効果**: Pod installの時間を大幅削減（依存数により2-10分 → 数秒）

## Carthage

```yaml
- name: Cache Carthage
  uses: actions/cache@v4
  with:
    path: Carthage
    key: ${{ runner.os }}-carthage-${{ hashFiles('**/Cartfile.resolved') }}
    restore-keys: |
      ${{ runner.os }}-carthage-

- name: Carthage Bootstrap
  run: carthage bootstrap --platform iOS --use-xcframeworks
```

## DerivedData（増分ビルド）

```yaml
- name: Cache DerivedData
  uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-derived-${{ hashFiles('**/*.swift', '**/*.xib', '**/*.storyboard') }}
    restore-keys: |
      ${{ runner.os }}-derived-
```

**注意**: DerivedDataキャッシュは効果が限定的な場合あり。依存キャッシュを優先。

## Ruby/Bundler（Fastlane用）

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.2'
    bundler-cache: true  # 自動キャッシュ
```

## 複合キャッシュ（推奨構成）

```yaml
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      # 1. SPMキャッシュ
      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: |
            ~/Library/Caches/org.swift.swiftpm
            .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      # 2. CocoaPodsキャッシュ（使用時）
      - name: Cache CocoaPods
        if: hashFiles('Podfile.lock') != ''
        uses: actions/cache@v4
        with:
          path: Pods
          key: ${{ runner.os }}-pods-${{ hashFiles('**/Podfile.lock') }}
          restore-keys: ${{ runner.os }}-pods-

      - name: Install Pods
        if: hashFiles('Podfile.lock') != ''
        run: pod install

      # 3. ビルド
      - name: Build
        run: xcodebuild build ...
```

## キャッシュサイズ制限

GitHub Actionsのキャッシュ制限:
- **リポジトリあたり10GB**
- 7日間アクセスがないキャッシュは自動削除

大規模プロジェクトでは以下を検討:
1. 必要なキャッシュのみ保持
2. キャッシュキーを適切に設計（頻繁に変わるファイルを除外）
3. DerivedDataはキャッシュしない（サイズ大）
