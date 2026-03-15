---
name: python-development
description: モダンPython開発の標準ワークフロー。uv（仮想環境・依存管理）、ruff（Lint/Format）、pytest（テスト）、型チェック、pre-commitによるGit hooksを統合したベストプラクティスを提供する。スクリプト実行、新規プロジェクト作成、依存パッケージ追加、コード品質チェック、テスト実行など、Pythonプロジェクトやスクリプトのあらゆるフェーズで自動適用する。「Pythonスクリプト作って」「uvで環境作って」「ruffでチェックして」「pytest実行して」「Pythonプロジェクト初期化」「pyproject.toml」「依存追加」「仮想環境」「型チェック」などのキーワードでも積極的に使用。
---

# Python Development Skill

uv・ruff を中心としたモダン Python 開発の標準ワークフロー。

## ツールスタックの概要

| ツール | 役割 | 旧来の代替 |
|--------|------|-----------|
| **uv** | 環境・依存・Pythonバージョン管理 | pip + venv + pyenv + pip-tools |
| **ruff** | Lint + Format | flake8 + black + isort + pyupgrade |
| **pytest** | テスト実行 | unittest |
| **mypy** / **pyright** | 静的型チェック | なし |
| **pre-commit** | Git hooks による品質ゲート | 手動 |
| **pyproject.toml** | 全設定の一元化 | setup.cfg + .flake8 + requirements.txt |

---

## 新規プロジェクト作成

```bash
# アプリケーション（実行バイナリが必要な場合）
uv init my-app --app

# ライブラリ（パッケージとして配布する場合）
uv init my-lib --lib

# 単発スクリプト
uv init my-script --script
```

### 初期化後の標準手順

```bash
cd my-app

# Python バージョンを固定（.python-version が生成される）
uv python pin 3.12

# 開発依存を追加
uv add --dev ruff pytest pytest-cov mypy pre-commit

# 環境同期（.venv が自動生成される）
uv sync
```

---

## 仮想環境・依存管理（uv）

詳細は `references/uv-workflow.md` を参照。

```bash
# パッケージ追加（pyproject.toml と uv.lock が自動更新される）
uv add requests httpx

# 開発用ツールの追加
uv add --dev pytest ruff

# パッケージ削除
uv remove requests

# ロックファイルから完全再現インストール
uv sync

# スクリプト実行（venv を意識せず実行できる）
uv run python my_script.py
uv run pytest
uv run ruff check .

# 一時的にツールを実行（インストール不要）
uvx ruff check .
uvx mypy src/
```

---

## コード品質チェック（ruff）

詳細な設定例は `references/ruff-config.md` を参照。

```bash
# Lint チェック
uv run ruff check .

# 自動修正
uv run ruff check --fix .

# フォーマット確認
uv run ruff format --check .

# フォーマット適用
uv run ruff format .

# Lint + Format を一括実行
uv run ruff check --fix . && uv run ruff format .
```

### pyproject.toml への ruff 設定（最小構成）

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"
```

---

## テスト（pytest）

```bash
# テスト実行
uv run pytest

# カバレッジ付きで実行
uv run pytest --cov=src --cov-report=term-missing

# 特定ファイル・関数のみ
uv run pytest tests/test_api.py::test_fetch_data -v

# 失敗したテストのみ再実行
uv run pytest --lf
```

### pyproject.toml への pytest 設定

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["-v", "--tb=short"]

[tool.coverage.run]
source = ["src"]
omit = ["tests/*"]
```

---

## 型チェック（mypy / pyright）

```bash
# mypy
uv run mypy src/

# pyright（高速かつ VSCode 標準）
uvx pyright src/
```

### pyproject.toml への mypy 設定

```toml
[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
```

---

## Git Hooks（pre-commit）

```bash
# .pre-commit-config.yaml を作成後、フックをインストール
uv run pre-commit install

# 全ファイルに手動実行
uv run pre-commit run --all-files
```

`.pre-commit-config.yaml` の標準構成：

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
```

---

## 標準的なディレクトリ構成

詳細なテンプレートは `references/project-templates.md` を参照。

```
my-app/
├── pyproject.toml       # 全設定の一元管理
├── uv.lock              # 再現性を保証するロックファイル（必ずGit管理）
├── .python-version      # Python バージョンの固定
├── .pre-commit-config.yaml
├── src/
│   └── my_app/
│       ├── __init__.py
│       └── main.py
└── tests/
    ├── conftest.py
    └── test_main.py
```

> **src layout 推奨**: `src/` 以下にパッケージを置くことで、インストール済みパッケージとのパス競合を防ぐ。

---

## ワークフロー早見表

| 作業 | コマンド |
|------|---------|
| 新規プロジェクト作成 | `uv init <name> --app` |
| パッケージ追加 | `uv add <pkg>` |
| 開発ツール追加 | `uv add --dev <pkg>` |
| スクリプト実行 | `uv run python <script>` |
| Lint チェック&修正 | `uv run ruff check --fix .` |
| フォーマット | `uv run ruff format .` |
| テスト実行 | `uv run pytest` |
| 型チェック | `uv run mypy src/` |

---

## References

| ファイル | 内容 |
|---------|------|
| `references/uv-workflow.md` | uv コマンドの詳細・CI/CD パターン |
| `references/ruff-config.md` | ruff のルールセット詳細・設定例 |
| `references/project-templates.md` | pyproject.toml テンプレート・GitHub Actions 例 |
