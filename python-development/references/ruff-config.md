# ruff 設定リファレンス

## ruff とは

Rust 製の超高速 Python Linter + Formatter。
`flake8`, `black`, `isort`, `pyupgrade`, `pydocstyle`, `autoflake` などの機能を単一ツールに統合。

---

## コマンドリファレンス

```bash
# Lint チェック（エラーのみ表示）
uv run ruff check .

# 自動修正可能なエラーを修正
uv run ruff check --fix .

# unsafe な修正も含めて一括修正
uv run ruff check --fix --unsafe-fixes .

# 特定ファイル・ディレクトリ
uv run ruff check src/ tests/

# フォーマット確認（差分のみ表示）
uv run ruff format --check .

# フォーマット適用
uv run ruff format .

# ルール一覧を確認
uv run ruff rule --all

# 特定のルール説明
uv run ruff rule E501
```

---

## pyproject.toml への設定

### ミニマル構成（入門向け）

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I"]   # pycodestyle + pyflakes + isort
```

### 推奨構成（中規模プロジェクト）

```toml
[tool.ruff]
target-version = "py312"
line-length = 88
src = ["src"]              # src layout の場合に指定

[tool.ruff.lint]
select = [
  "E",    # pycodestyle エラー
  "W",    # pycodestyle 警告
  "F",    # pyflakes（未使用 import, 未定義変数）
  "I",    # isort（import 順序）
  "UP",   # pyupgrade（Python バージョン対応のアップグレード）
  "B",    # flake8-bugbear（よくあるバグパターン）
  "SIM",  # flake8-simplify（冗長コードの簡略化）
  "C4",   # flake8-comprehensions（内包表記の最適化）
  "N",    # pep8-naming（命名規則）
]
ignore = [
  "E501",   # line too long（formatter に委ねる）
  "B008",   # function call in default argument
  "N999",   # Invalid module name（スクリプト名が含まれる場合）
]

[tool.ruff.lint.isort]
known-first-party = ["mypackage"]  # 自社パッケージの扱い

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true       # docstring 内のコード例もフォーマット
```

### 厳格構成（高品質ライブラリ向け）

```toml
[tool.ruff]
target-version = "py312"
line-length = 88
src = ["src"]

[tool.ruff.lint]
select = [
  "E", "W", "F", "I",
  "UP",     # pyupgrade
  "B",      # bugbear
  "SIM",    # simplify
  "C4",     # comprehensions
  "N",      # naming
  "D",      # pydocstyle（docstring チェック）
  "ANN",    # flake8-annotations（型注釈の強制）
  "PTH",    # flake8-use-pathlib（os.path 廃止）
  "RUF",    # Ruff 固有ルール
  "TRY",    # tryceratops（例外処理のベストプラクティス）
  "PERF",   # Perflint（パフォーマンス改善）
]
ignore = [
  "E501",
  "D100",   # Missing docstring in public module
  "D104",   # Missing docstring in public package
  "ANN101", # Missing type annotation for `self`
]

[tool.ruff.lint.pydocstyle]
convention = "google"   # google / numpy / pep257

[tool.ruff.format]
quote-style = "double"
docstring-code-format = true
```

---

## 主要ルールセットの説明

| コード | 名称 | 概要 |
|--------|------|------|
| `E`, `W` | pycodestyle | PEP 8 準拠チェック |
| `F` | pyflakes | 未使用 import・変数の検出 |
| `I` | isort | import 文の自動整理 |
| `UP` | pyupgrade | Python バージョンに合わせた構文アップグレード |
| `B` | flake8-bugbear | バグになりやすいパターンの検出 |
| `SIM` | flake8-simplify | 冗長な条件式・コードの簡略化提案 |
| `C4` | flake8-comprehensions | リスト/dict/set 内包表記の最適化 |
| `N` | pep8-naming | クラス/関数/変数の命名規則チェック |
| `D` | pydocstyle | docstring の形式チェック |
| `ANN` | flake8-annotations | 型注釈の強制 |
| `PTH` | flake8-use-pathlib | `os.path` → `pathlib.Path` への移行 |
| `RUF` | Ruff 固有 | Ruff 独自の追加ルール |
| `TRY` | tryceratops | `try/except` の適切な使い方 |
| `PERF` | Perflint | パフォーマンス改善の提案 |

---

## ファイル・ルールの除外

```toml
[tool.ruff]
exclude = [
  ".venv",
  "__pycache__",
  "*.pyi",
  "migrations/",  # Django マイグレーションなど自動生成ファイル
]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
  "ANN",    # テストファイルは型注釈を強制しない
  "S101",   # assert の使用を許可
]
"scripts/*.py" = ["D"]  # スクリプトは docstring 不要
```

---

## noqa コメント（個別抑制）

```python
import os  # noqa: F401          # 特定ルールを無視
import sys  # noqa               # すべてのルールを無視（非推奨）

x: int = 1  # type: ignore       # mypy も無視
```

---

## pre-commit との連携

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0   # 最新バージョンに更新すること
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

> `ruff` と `ruff-format` の順序は固定。`ruff`（lint）で修正後、`ruff-format` でフォーマットする。
