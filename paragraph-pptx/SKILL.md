---
name: paragraph-pptx
description: "Create academic and research presentations using the パラグラフテンプレート (paragraph template) — a custom 4:3 slide template with topic-header/message/supporting-content structure. Use this skill whenever the user mentions template.pptx, パラグラフテンプレート, パラグラフスライド, 学術発表スライド, 研究プレゼン, or wants to create slides with topic+message+supporting-detail structure. Also trigger when the user references slide duplication for animation, yellow highlight frames, Memo bars, card layouts (3-card/4-card), or any of the design patterns specific to this template. If the user has template.pptx in their working directory and asks to create a presentation, use this skill."
---

# パラグラフテンプレート スキル

template.pptx を使った学術発表・研究プレゼンテーション作成ガイド。

このスキルは既存の **pptx スキル**（unpack→edit→pack ワークフロー）の上に乗るテンプレート固有の知識を提供する。pptx スキルの `editing.md` に記載されたワークフローとスクリプト群をそのまま使い、本スキルはテンプレートの構造・デザインパターン・XML スニペットを補完する。

## テンプレート概要

| 項目 | 値 |
|------|-----|
| スライドサイズ | 4:3 (10" × 7.5" / 9144000 × 6858000 EMU) |
| フォント（見出し） | 游ゴシック Bold |
| フォント（本文） | 游ゴシック Medium |
| メインレイアウト | slideLayout13.xml（パラグラフスライド） |
| タイトルレイアウト | slideLayout1.xml |
| テンプレートファイル | template.pptx |

## テンプレートスライド一覧

| slide | 用途 | いつ複製するか |
|-------|------|---------------|
| slide1 | タイトルページ | 表紙 |
| slide2 | **空のパラグラフ** | 通常のコンテンツスライド（最も頻繁に使う） |
| slide3 | 図形パターン例 | 参考用（通常は複製しない） |
| slide4 | 循環図パターン | 参考用（通常は複製しない） |
| slide5 | 3カード（並列） | 3項目の並列比較 |
| slide6 | 3カード（階段） | 3項目の順序付き比較 |
| slide7 | 4カード（2×2） | 4項目の比較・分類 |
| slide8 | 4カード（循環） | 4項目の循環関係 |

基本は **slide2 を複製**してコンテンツスライドを作る。カード比較が必要なときだけ slide5〜8 を使う。

## パラグラフスライドの3層構造

パラグラフスライド（slideLayout13）は「問い→答え→根拠」の3層で1つのメッセージを伝える設計になっている。学術発表では「聴衆が今何を考えるべきか（話題）」→「その答え（メッセージ）」→「なぜそう言えるか（補足）」の流れが明快さの鍵になる。

```
┌──────────────────────────────────────────────┐
│ [話題＝問い] (idx=11)              [ページ番号] │
│──────────────────────────────────────────────│  ← 水平線 y=825500
│                                               │
│ [メッセージ＝答え] (type="title")              │
│                                               │
│ [補足説明] (idx=1)                             │
│   ● 根拠・解説・具体例                          │
│     ● 第2段                                    │
└──────────────────────────────────────────────┘
```

### 1. 話題ヘッダー（idx="11", type="body"）
- 位置: 上部 (x=157931, y=348226, w=8591550, h=469900)
- 游ゴシック Medium、太字なし
- スライドのトピック（問い）を書く。「背景：なぜ〇〇が必要か」「提案手法：〇〇」のように

### 2. メッセージ（type="title"）
- 位置: 話題の下 (x=419100, y=1016002, w=8324850, h=938159)
- 游ゴシック Bold 27pt
- そのスライドで伝えたい一言（問いへの答え）。1〜2行に収める

### 3. 補足説明（idx="1"）
- 位置: メッセージの下 (x=419100, y=2013155, w=8324850, h=4572000)
- Wingdings bullet "l"（黒丸）、5段階インデント
- テキスト箇条書き以外の用途（図・グラフ等）では、このプレースホルダーのテキストを空にして自由配置の図形やテキストボックスを追加する

## テーマカラー（theme2）

パラグラフスライドはスライドマスター2（theme2 = グレー基調）を使う。

| スキーム名 | 色コード | 用途の目安 |
|-----------|----------|-----------|
| dk1 | `4D4D4D` | メインテキスト |
| lt1 | `F8F8F8` | 背景 |
| accent1 | `7F7F7F` | グレーアクセント |
| accent2 | `B2B2B2` | 薄グレー |
| accent3 | `2E5B96` | **青**（重要な強調） |
| accent4 | `C03936` | **赤**（警告・注意） |
| accent5 | `ED7D31` | オレンジ |
| accent6 | `3E9288` | **ティール**（Memo バー、カード枠、矢印） |

よく使う追加色:
- `FFFF00` — 黄色（ハイライト枠）
- `000000` — 黒（課題ボックス背景）
- `FF0000` / `0000FF` — 赤・青（テキスト強調）

## ワークフロー

pptx スキルの editing.md のワークフローに従う。テンプレート固有のポイントだけ補足する。

### 1. unpack
```bash
python3 scripts/office/unpack.py template.pptx unpacked/
```

### 2. スライド構成を計画
presentation.xml の `<p:sldIdLst>` を確認。通常スライド → slide2 複製、カード → slide5〜8 複製。

### 3. スライド追加
```bash
python3 scripts/add_slide.py unpacked/ slide2.xml   # パラグラフスライド
python3 scripts/add_slide.py unpacked/ slide5.xml   # 3カード
python3 scripts/add_slide.py unpacked/ slide7.xml   # 4カード
```
出力される `<p:sldId>` を presentation.xml に挿入し、不要なテンプレートスライド（slide3〜8 の説明用）は削除する。

### 4. コンテンツ編集
各スライドの XML を Edit ツールで直接編集する。

- 話題ヘッダー（idx="11"）→ トピックテキストを書き換え
- メッセージ（type="title"）→ メッセージテキストを書き換え
- 補足説明（idx="1"）→ テキスト箇条書き or 空にして自由配置

図形・テキストボックスの追加が必要なときは [references/xml-patterns.md](references/xml-patterns.md) の XML スニペットをコピペする。

### 5. clean & pack
```bash
python3 scripts/clean.py unpacked/
python3 scripts/office/pack.py unpacked/ output.pptx --original template.pptx
```

## デザインパターン

サンプル（sample1.pptx, sample2.pptx）で頻出するパターン。XML は [references/xml-patterns.md](references/xml-patterns.md) を参照。

### カード型レイアウト（3枚・4枚）
slide5〜8 を複製して使う。各カードは rect 枠 + テキストボックス。枠線は accent6（ティール）幅 19050 EMU。カード見出し＋説明テキストを内側に配置する。

### ハイライト枠（黄色）
`roundRect`、noFill、枠線 `FFFF00` 幅 57150 EMU。段階表示で「今ここに注目」を示すために使う。

### Memo バー
スライド下部（y≈6290000）の注記欄。ティール塗りの "Memo" ラベル + 右隣のテキストボックスの2要素。

### 黒背景ボックス
solidFill `000000` + 白テキスト。カード下部に重ねて課題・デメリットを表示。

### 矢印・フロー
`rightArrow` 等の prstGeom。accent6（ティール）で塗りつぶし。

## アニメーション（段階表示）

PowerPoint のアニメーション機能は使わない。代わりに**スライド複製**で段階表示を実現する。

1. 最終状態のスライドを作る
2. 必要回数だけ複製する
3. 早い段階の複製から要素を段階的に削除（最初の複製が最も要素が少ない）
4. presentation.xml で正しい順序に並べる

ハイライトも同様：複製ごとに黄色枠の位置を変えて注目箇所を移動させる。

## フォント指定（XML）

```xml
<!-- 游ゴシック (Regular/Bold) -->
<a:latin typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>
<a:ea typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>

<!-- 游ゴシック Medium -->
<a:latin typeface="游ゴシック Medium" panose="020B0500000000000000" pitchFamily="50" charset="-128"/>
<a:ea typeface="游ゴシック Medium" panose="020B0500000000000000" pitchFamily="50" charset="-128"/>
```

## EMU 変換

| 単位 | EMU |
|------|-----|
| 1 inch | 914400 |
| 1 cm | 360000 |
| 1 pt | 12700 |
| スライド幅 | 9144000 (10") |
| スライド高さ | 6858000 (7.5") |
