# Figma/Sketch Template Reference

iOSアプリアイコン作成用のデザインテンプレート情報。

## Figma Template Setup

### キャンバス設定

```
サイズ: 1024 × 1024 px
背景: 単色または軽いグラデーション（透明不可）
カラースペース: Display P3 または sRGB
```

### グリッドシステム

Appleの公式アイコングリッドに準拠：

```
┌──────────────────────────────────┐
│  ┌──────────────────────────┐    │
│  │                          │    │
│  │    ┌──────────────┐      │    │
│  │    │              │      │    │
│  │    │    ICON      │      │    │
│  │    │    AREA      │      │    │
│  │    │              │      │    │
│  │    └──────────────┘      │    │
│  │                          │    │
│  └──────────────────────────┘    │
└──────────────────────────────────┘

外側マージン: 24px (全方向)
安全エリア: 中央 800x800 px
最小パディング: 120px
```

### レイヤー構成

```
📁 App Icon
  ├── 🎨 Background
  │   └── 背景色またはグラデーション
  ├── 🔷 Main Element
  │   └── メインのアイコン要素
  └── ✨ Details (optional)
      └── アクセント要素
```

## デザインチェックリスト

### 基本要件

- [ ] サイズが 1024×1024 px
- [ ] 角丸を適用していない（OSが自動処理）
- [ ] 透明ピクセルがない
- [ ] 背景が単色または軽いグラデーション

### 視認性

- [ ] 小サイズ (29px) でも識別可能
- [ ] 高コントラスト
- [ ] シンプルな形状

### カラー

- [ ] 2-4色に限定
- [ ] Display P3 または sRGB
- [ ] ダークモード背景でも見やすい

### コンテンツ

- [ ] テキストを使用していない（または最小限）
- [ ] 著作権に問題がない
- [ ] ブランドガイドラインに準拠

## エクスポート設定

### Figma

```
フォーマット: PNG
スケール: 1x
背景: 含める
```

### Sketch

```
フォーマット: PNG
解像度: 1x
背景: 含める
```

### Illustrator

```
フォーマット: PNG
解像度: 1024 × 1024 px
カラーモード: RGB
アンチエイリアス: アート最適化
```

## Apple公式リソース

- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Apple Design Resources](https://developer.apple.com/design/resources/)
- [App Icon Template (Figma Community)](https://www.figma.com/community/file/857303226040719059)
