# iOS 18+ Dark Mode & Tinted Icons

iOS 18以降で導入されたダークモード・ティンテッドアイコン対応ガイド。

## 概要

iOS 18では、ユーザーがホーム画面のアイコン表示を3種類から選択可能：

1. **Light（標準）** - 従来のフルカラーアイコン
2. **Dark** - ダークモード最適化アイコン
3. **Tinted** - ユーザー選択色でモノクロ化

## バリアント仕様

### Light（必須）

- 従来のフルカラーアイコン
- 全アプリで必須

### Dark（オプション）

- ダークモード用に最適化されたバージョン
- 背景を暗くし、アイコン要素を明るく

```
設計ポイント:
- 背景: 暗い色（#1C1C1E推奨）
- 前面要素: 明るい色または鮮やかな色
- コントラスト比を維持
```

### Tinted（オプション）

- ユーザーが選択した色相で自動着色
- モノクロ（グレースケール）で提供

```
設計ポイント:
- 純粋なグレースケールで作成
- 形状のみで識別可能に
- アルファチャンネルで透明度を表現
```

## Xcode設定

### Assets.xcassetsでの設定

1. AppIcon.appiconsetを選択
2. Attributesインスペクターで「Appearances」を設定:
   - Any, Dark
   - Any, Dark, Tinted（iOS 18+）

### Contents.json構造

```json
{
  "images": [
    {
      "filename": "icon-60@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "filename": "icon-60@2x-dark.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "tinted"
        }
      ],
      "filename": "icon-60@2x-tinted.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

## デザインベストプラクティス

### Darkバリアント

```
推奨:
✓ 背景を暗くする
✓ アクセントカラーを維持
✓ ダークモードUIとの調和

避ける:
✗ 単純な色反転
✗ 黒一色の背景
✗ 低コントラスト
```

### Tintedバリアント

```
推奨:
✓ 純粋なグレースケール
✓ 明確なシルエット
✓ 適度な透明度バリエーション

避ける:
✗ カラー情報を含める
✗ 細すぎるディテール
✗ グラデーションへの依存
```

## ファイル命名規則

```
AppIcon.appiconset/
├── icon-60@2x.png         # Light
├── icon-60@2x-dark.png    # Dark
├── icon-60@2x-tinted.png  # Tinted
├── icon-60@3x.png         # Light
├── icon-60@3x-dark.png    # Dark
├── icon-60@3x-tinted.png  # Tinted
└── ...
```

## 検証チェックリスト

- [ ] Light版が全サイズ揃っている
- [ ] Dark版のコントラストが十分
- [ ] Tinted版が純粋なグレースケール
- [ ] Contents.jsonのappearances設定が正しい
- [ ] シミュレーターで3モード全て確認
