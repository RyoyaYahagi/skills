---
name: manim-math-animation
description: >-
  数学の概念を幾何学的に視覚化するManimアニメーションを作成するスキル。
  Use when asked to create math animations, visualize mathematical concepts geometrically,
  explain optimization/convex analysis/linear algebra with Manim, or produce educational
  math videos. Triggers on: 「数学の概念をアニメーションで説明して」「〇〇を幾何学的に可視化して」
  「Manimでアニメーションを作成して」etc.
---

# Manim Mathematical Concept Animation

数学の概念を幾何学的に視覚化するManimアニメーションを作成する。

## 技術スタック

- **ライブラリ**: Manim Community Edition (v0.18+)
- **Python**: 3.10+
- **パッケージ管理**: uv推奨

## コード構造テンプレート

```python
"""
[概念名] の幾何学的解説アニメーション

使用方法:
    manim -pql filename.py ClassName
"""

from manim import *


class ConceptNameScene(Scene):
    """概念の説明"""

    def construct(self):
        self.phase_one()
        self.wait(0.5)
        self.phase_two()
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=1.0)

    def phase_one(self):
        """Phase 1"""
        pass

    def phase_two(self):
        """Phase 2"""
        pass
```

## ディレクトリ構成

```
project/
├── pyproject.toml
├── main.py
└── media/         # 出力ディレクトリ（自動生成）
```

## 実行コマンド

```bash
manim -pql scene.py SceneName    # プレビュー品質
manim -pqh scene.py SceneName    # 高品質
manim -pqk scene.py SceneName    # 4K品質
```

## リソース

- **詳細なコードパターン**: [references/patterns.md](references/patterns.md)を参照
  - 座標軸の設定、ValueTracker、MathTex、カラーパレット、アニメーションパターン等

## 典型的なユースケース

- **凸解析**: Fenchel Conjugate、Strong Convexity、Lipschitz Continuity
- **最適化**: Gradient Descent、Lagrange Duality、KKT Conditions
- **線形代数**: 固有値・固有ベクトル、特異値分解、線形変換
