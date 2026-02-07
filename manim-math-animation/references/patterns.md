# Manim コードパターン

## 必須要素

### 1. 座標軸の設定

```python
self.axes = Axes(
    x_range=[-3, 3, 1],
    y_range=[-1, 5, 1],
    x_length=10,
    y_length=6,
    axis_config={
        "include_numbers": True,
        "font_size": 20,
        "include_tip": True,
    },
).shift(DOWN * 0.3)

axes_labels = self.axes.get_axis_labels(x_label="x", y_label="f(x)")
self.play(Create(self.axes), Write(axes_labels))
```

### 2. 動的要素には ValueTracker + always_redraw

```python
# ValueTracker でパラメータ管理
self.p_tracker = ValueTracker(1.0)

# always_redraw で自動更新
self.point = always_redraw(
    lambda: Dot(
        self.axes.c2p(
            self.p_tracker.get_value(),
            f(self.p_tracker.get_value())
        ),
        color=YELLOW,
        radius=0.12,
    )
)

# アニメーション
self.play(self.p_tracker.animate.set_value(2.0), run_time=2.0)
```

### 3. 数式表示には MathTex

```python
# 単独の数式
formula = MathTex(r"f(x) = x^2", color=BLUE, font_size=28)

# 数式グループ
explanation = VGroup(
    MathTex(r"f^*(u) = \sup_x \{ ux - f(x) \}", font_size=24),
    Text("凸共役の定義", font="Hiragino Sans", font_size=20),
).arrange(DOWN, aligned_edge=LEFT, buff=0.15)
```

### 4. 説明ボックス

```python
explanation_box = SurroundingRectangle(
    explanation,
    color=WHITE,
    fill_color=BLACK,
    fill_opacity=0.85,
    buff=0.15,
    corner_radius=0.1,
)
self.play(FadeIn(explanation_box), Write(explanation))
```

### 5. 関数曲線の描画

```python
def f(x):
    return x**2

curve = self.axes.plot(
    f,
    x_range=[-2.2, 2.2],
    color=BLUE,
    stroke_width=4,
)
self.play(Create(curve), run_time=1.5)
```

### 6. 破線の作成

```python
# 接線などを破線で表示
tangent = self.axes.plot(
    lambda x: py + slope * (x - px),
    x_range=[x_min, x_max],
    color=YELLOW,
    stroke_width=2,
)
dashed_tangent = DashedVMobject(tangent, num_dashes=30)
```

---

## カラーパレット

| 用途          | 色       | Manim定数 |
| ------------- | -------- | --------- |
| メイン関数    | 青       | `BLUE`    |
| サブ関数/下界 | 赤       | `RED`     |
| 点/接線       | 黄       | `YELLOW`  |
| ギャップ/差分 | 緑       | `GREEN`   |
| 補助/追加     | オレンジ | `ORANGE`  |

---

## アニメーションパターン

### 基本的なアニメーション

```python
self.play(Create(mobject), run_time=1.5)       # 描画
self.play(Write(text), run_time=1.0)           # テキスト
self.play(FadeIn(mobject), run_time=0.8)       # フェードイン
self.play(FadeOut(mobject), run_time=0.5)      # フェードアウト
self.play(GrowFromCenter(dot), run_time=0.8)   # 中心から成長
self.wait(0.5)                                  # 待機
```

### 動的パラメータ変化

```python
self.play(
    self.tracker.animate.set_value(2.0),
    run_time=2.5,
    rate_func=smooth,
)
```

### 複数オブジェクトの同時変化

```python
self.play(
    self.p_tracker.animate.set_value(1.0),
    self.gamma_tracker.animate.set_value(0.5),
    run_time=2.5,
)
```

---

## 日本語対応

日本語テキストには適切なフォントを指定:

```python
Text(
    "強凸関数は、接する放物線よりもさらに上にある",
    font="Hiragino Sans",  # macOS
    # font="Noto Sans CJK JP",  # Linux
    font_size=20,
)
```

---

## ベストプラクティス

1. **Phase分割**: 複雑な概念は複数のPhaseに分割し、各Phaseをメソッドとして実装
2. **日本語コメント**: コードには日本語でコメントを追加
3. **docstring**: クラスとメソッドにはdocstringで説明を記載
4. **wait()の活用**: アニメーション間に適切な`wait()`を入れて視聴者の理解を助ける
5. **動的要素**: パラメータの変化を見せる場合は`ValueTracker`と`always_redraw`を使用
6. **色分け**: 要素の役割に応じて一貫したカラーパレットを使用
7. **最後のクリーンアップ**: シーン終了時に`FadeOut`で全オブジェクトを消去
