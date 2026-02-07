# Quality Checks for iOS CI

## SwiftLint

### インストール

```bash
# Homebrew
brew install swiftlint

# Mint
mint install realm/SwiftLint

# SPM Plugin（Swift 5.9+）
# Package.swiftに追加
.package(url: "https://github.com/realm/SwiftLint.git", from: "0.54.0")
```

### 基本設定 (.swiftlint.yml)

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional

excluded:
  - Pods
  - .build
  - DerivedData
  - "**/Generated"

line_length:
  warning: 120
  error: 200

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

identifier_name:
  min_length: 2
  excluded:
    - id
    - x
    - y
```

### GitHub Actions Step

```yaml
- name: SwiftLint
  run: swiftlint lint --strict --reporter github-actions-logging
```

## Danger

### インストール

```ruby
# Gemfile
gem 'danger'
gem 'danger-swiftlint'
gem 'danger-xcov'
```

### 基本設定 (Dangerfile)

```ruby
# Dangerfile

# PRの説明が空の場合に警告
warn("PR description is empty") if github.pr_body.length < 10

# 大きすぎるPRに警告
warn("Big PR") if git.lines_of_code > 500

# テストファイルがない変更に警告
has_app_changes = !git.modified_files.grep(/Sources/).empty?
has_test_changes = !git.modified_files.grep(/Tests/).empty?
if has_app_changes && !has_test_changes
  warn("Tests were not updated. Consider adding tests.")
end

# SwiftLint
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true

# TODO/FIXME検出
todoist.warn_for_todos
todoist.print_todos_table
```

### GitHub Actions Step

```yaml
- name: Danger
  env:
    DANGER_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: bundle exec danger
```

## テストカバレッジ

### Xcode結果バンドルからカバレッジ抽出

```yaml
- name: Extract Coverage
  run: |
    xcrun xccov view --report TestResults.xcresult --json > coverage.json
    # カバレッジ率を抽出
    COVERAGE=$(cat coverage.json | jq '.lineCoverage * 100 | floor')
    echo "Coverage: ${COVERAGE}%"
    echo "COVERAGE=${COVERAGE}" >> $GITHUB_ENV

- name: Comment Coverage
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        body: `📊 Test Coverage: **${{ env.COVERAGE }}%**`
      })
```

## formatチェック（swift-format）

```yaml
- name: Check Formatting
  run: |
    brew install swift-format
    swift-format lint --recursive Sources Tests
```
