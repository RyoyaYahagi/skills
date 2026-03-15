# プロジェクトテンプレート

## ディレクトリ構成

### src layout（推奨）

パッケージを `src/` 以下に置くことで、開発時のパスとインストール済みパッケージのパスが分離され、意図しない動作を防ぐ。

```
my-app/
├── pyproject.toml
├── uv.lock
├── .python-version          # uv python pin で生成
├── .pre-commit-config.yaml
├── README.md
├── src/
│   └── my_app/
│       ├── __init__.py
│       ├── main.py
│       └── core/
│           ├── __init__.py
│           └── service.py
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── __init__.py
    │   └── test_service.py
    └── integration/
        ├── __init__.py
        └── test_api.py
```

### flat layout（小規模・スクリプト向け）

```
my-script/
├── pyproject.toml
├── uv.lock
├── .python-version
├── main.py
└── tests/
    └── test_main.py
```

---

## pyproject.toml テンプレート

### アプリケーション向け（完全版）

```toml
[project]
name = "my-app"
version = "0.1.0"
description = "アプリの説明"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
  "httpx>=0.27",
  "pydantic>=2.6",
]

[project.scripts]
my-app = "my_app.main:main"    # CLI エントリーポイント

[dependency-groups]
dev = [
  "ruff>=0.9",
  "pytest>=8",
  "pytest-cov>=5",
  "mypy>=1.9",
  "pre-commit>=3.7",
]

[build-system]
requires = ["hatchling"]       # uv デフォルトのビルドバックエンド
build-backend = "hatchling.build"

# ─── ruff ───────────────────────────────────────────
[tool.ruff]
target-version = "py312"
line-length = 88
src = ["src"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "UP", "B", "SIM", "C4", "N", "RUF"]
ignore = ["E501"]

[tool.ruff.lint.isort]
known-first-party = ["my_app"]

[tool.ruff.format]
quote-style = "double"
docstring-code-format = true

# ─── pytest ─────────────────────────────────────────
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["-v", "--tb=short"]

[tool.coverage.run]
source = ["src"]
branch = true
omit = ["tests/*", "*/migrations/*"]

[tool.coverage.report]
show_missing = true
fail_under = 80    # カバレッジ 80% 未満で CI 失敗

# ─── mypy ───────────────────────────────────────────
[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
```

### ライブラリ向け

```toml
[project]
name = "my-lib"
version = "0.1.0"
description = "ライブラリの説明"
readme = "README.md"
requires-python = ">=3.11"    # ライブラリは広い範囲をサポート
license = { text = "MIT" }
authors = [{ name = "Your Name", email = "you@example.com" }]
keywords = ["python", "library"]
classifiers = [
  "Programming Language :: Python :: 3",
  "License :: OSI Approved :: MIT License",
  "Operating System :: OS Independent",
]
dependencies = []    # 最小限に留める

[project.urls]
Repository = "https://github.com/you/my-lib"
Documentation = "https://my-lib.readthedocs.io"

[dependency-groups]
dev = [
  "ruff>=0.9",
  "pytest>=8",
  "pytest-cov>=5",
  "mypy>=1.9",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

---

## GitHub Actions テンプレート

### 基本的な CI パイプライン

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12", "3.13"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up uv
        uses: astral-sh/setup-uv@v5
        with:
          version: "latest"
          enable-cache: true

      - name: Set up Python ${{ matrix.python-version }}
        run: uv python install ${{ matrix.python-version }}

      - name: Install dependencies
        run: uv sync --frozen

      - name: Lint (ruff)
        run: |
          uv run ruff check .
          uv run ruff format --check .

      - name: Type check (mypy)
        run: uv run mypy src/

      - name: Test
        run: uv run pytest --cov=src --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage.xml
```

---

## .pre-commit-config.yaml テンプレート

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
      - id: trailing-whitespace   # 行末の空白を削除
      - id: end-of-file-fixer     # ファイル末尾の改行を保証
      - id: check-yaml            # YAML の構文チェック
      - id: check-toml            # TOML の構文チェック
      - id: check-merge-conflict  # マージコンフリクトマーカーの検出
      - id: debug-statements      # pdb/breakpoint 残留の検出
```

---

## conftest.py テンプレート

```python
# tests/conftest.py
import pytest


@pytest.fixture(scope="session")
def anyio_backend() -> str:
    """非同期テスト用バックエンド（anyio 使用時）。"""
    return "asyncio"


@pytest.fixture(autouse=True)
def reset_state() -> None:
    """各テスト前後でグローバル状態をリセット。"""
    yield
    # teardown 処理があればここに記述
```
