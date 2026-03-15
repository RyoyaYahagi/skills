# uv ワークフロー詳細リファレンス

## インストール

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Homebrew
brew install uv
```

---

## プロジェクト初期化

```bash
# アプリ（実行エントリーポイントあり）
uv init my-app --app

# ライブラリ（パッケージとして配布）
uv init my-lib --lib

# スクリプト（単一ファイル）
uv init my-script --script

# 現在のディレクトリで初期化
uv init .
```

生成されるファイル：

| ファイル | 説明 |
|---------|------|
| `pyproject.toml` | プロジェクト設定・依存関係 |
| `uv.lock` | バージョンをピン留めするロックファイル |
| `.python-version` | プロジェクトで使うPythonバージョン |
| `.venv/` | 仮想環境（自動作成） |

---

## Python バージョン管理

```bash
# インストール済みバージョン一覧
uv python list

# 特定バージョンをインストール
uv python install 3.12

# プロジェクトのバージョンを固定（.python-version に書き込まれる）
uv python pin 3.12

# 現在使用中のバージョン確認
uv python find
```

---

## 依存関係の管理

### パッケージの追加・削除

```bash
# 本番依存
uv add requests httpx pydantic

# 開発依存（テスト・Lint ツールなど）
uv add --dev ruff pytest pytest-cov mypy pre-commit

# オプショナル依存（パッケージ開発時）
uv add --optional dev ruff

# バージョン指定
uv add "requests>=2.31,<3"
uv add "pydantic==2.6.0"

# GitHub から直接追加
uv add "git+https://github.com/owner/repo.git"

# パッケージ削除
uv remove requests
```

### ロックファイルと同期

```bash
# pyproject.toml からロックファイルを更新
uv lock

# ロックファイルの内容を完全インストール（CI/CD 推奨）
uv sync

# 本番依存のみインストール（開発依存を除外）
uv sync --no-dev

# 特定グループのみインストール
uv sync --group dev
```

---

## スクリプト・コマンド実行

```bash
# 仮想環境内でコマンド実行（activate 不要）
uv run python main.py
uv run pytest
uv run ruff check .
uv run mypy src/

# 環境変数を設定して実行
uv run --env-file .env python main.py

# モジュールとして実行
uv run python -m mypackage

# シェルを起動（仮想環境が有効な状態）
uv shell
```

### 単発スクリプト（依存を inline で指定）

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "rich"]
# ///
import httpx
from rich import print

resp = httpx.get("https://api.example.com/data")
print(resp.json())
```

```bash
# 依存を自動インストールして実行
uv run script.py
```

---

## ツールの一時実行（uvx）

インストールなしで CLI ツールを実行する。

```bash
# ruff を一時実行
uvx ruff check .
uvx ruff format .

# mypy を一時実行
uvx mypy src/

# pyright を一時実行
uvx pyright src/

# black を一時実行（移行期など）
uvx black --check .
```

---

## CI/CD での uv 使用

### GitHub Actions

```yaml
- name: Set up uv
  uses: astral-sh/setup-uv@v5
  with:
    version: "latest"
    enable-cache: true        # 依存キャッシュで高速化

- name: Set up Python
  run: uv python install

- name: Install dependencies
  run: uv sync --frozen       # ロックファイルを厳密に適用

- name: Run tests
  run: uv run pytest --cov=src
```

> `--frozen` フラグでロックファイルの変更を禁止し、再現性を強制する。

---

## よく使うパターン

### Makefile への統合

```makefile
.PHONY: install lint format test check

install:
	uv sync

lint:
	uv run ruff check .

format:
	uv run ruff format .

test:
	uv run pytest --cov=src --cov-report=term-missing

check: lint format test
```

### パッケージのビルドと公開

```bash
# ビルド
uv build

# PyPI へ公開（uv publish は内部で twine を使用）
uv publish --token $PYPI_TOKEN
```
