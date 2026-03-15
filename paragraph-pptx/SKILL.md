---
name: paragraph-pptx
description: "Create academic and research presentations using the パラグラフテンプレート (paragraph template) — a custom 4:3 slide template with topic-header/message/supporting-content structure. Use this skill whenever the user mentions template.pptx, パラグラフテンプレート, パラグラフスライド, 学術発表スライド, 研究プレゼン, or wants to create slides with topic+message+supporting-detail structure. Also trigger when the user references slide duplication for animation, yellow highlight frames, Memo bars, card layouts (3-card/4-card), or any of the design patterns specific to this template. Prefer the bundled reference template at `references/template.pptx` unless the user explicitly supplies a different template."
---

# パラグラフテンプレート スキル

template.pptx を使った学術発表・研究プレゼンテーション作成ガイド。

このスキルは既存の **pptx スキル**（unpack→edit→pack ワークフロー）の上に乗るテンプレート固有の知識を提供する。pptx スキルの `editing.md` に記載されたワークフローとスクリプト群をそのまま使い、本スキルはテンプレートの構造・デザインパターン・XML スニペットを補完する。テンプレートの正本はこのスキル配下の `references/template.pptx` とし、ユーザーが別テンプレートを明示しない限りこのファイルを使う。

## テンプレート概要

| 項目 | 値 |
|------|-----|
| スライドサイズ | 4:3 (10" × 7.5" / 9144000 × 6858000 EMU) |
| フォント（見出し） | 游ゴシック Bold |
| フォント（本文） | 游ゴシック Medium |
| メインレイアウト | slideLayout13.xml（パラグラフスライド） |
| タイトルレイアウト | slideLayout1.xml |
| テンプレートファイル | `references/template.pptx`（正本） |

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

## テンプレート参照ルール

- 正式な参照元は `references/template.pptx`。eval もこのパスを使う。
- 既存の pptx ワークフローをそのまま使いたい場合は、作業ディレクトリへ `template.pptx` としてコピーしてから unpack / pack してよい。
- 直接パスを指定してもよいが、`unpack.py` と `pack.py --original` では同じテンプレートを参照する。
- ユーザーが別の `.pptx` を明示した場合のみ、そのファイルを優先する。

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
python3 scripts/office/unpack.py references/template.pptx unpacked/
```

既存ツールやスクリプトがカレントディレクトリの `template.pptx` を前提にしている場合は、先に `references/template.pptx` を作業ディレクトリへコピーしてから同じ手順を使ってよい。

### 2. スライド構成を計画
presentation.xml の `<p:sldIdLst>` を確認。各スライドの内容に応じて**表現形式を選択**する。

#### 表現形式の判断基準

スライドごとに「テキスト箇条書きで十分か、図解の方がわかりやすいか」を判断する。以下に該当する場合は**図解（図形・矢印・カード）を使う**：

| 内容のパターン | 推奨する表現 | 使うテンプレート/パターン |
|---------------|-------------|------------------------|
| 手順・プロセス・フロー | 矢印フロー図 | slide2 + 矢印図形（rightArrow 等） |
| 3項目の比較・並列 | 3カードレイアウト | slide5 または slide6 を複製 |
| 4項目の比較・分類 | 4カードレイアウト | slide7 または slide8 を複製 |
| 因果関係・変換 | ボックス＋矢印 | slide2 + テキストボックス＋矢印 |
| 構成要素・アーキテクチャ | ブロック図 | slide2 + rect 図形の組み合わせ |
| 課題と解決策の対比 | 黒背景ボックス＋カード | カードスライド + 黒背景ボックス |
| 循環・サイクル | 循環図 | slide4 または slide8 を複製 |
| 事実の列挙・説明 | テキスト箇条書き | slide2（従来通り） |

**原則：テキスト箇条書きだけのスライドは「事実の列挙・詳細説明」に限定する。関係性・流れ・比較がある内容は図解で表現する。**

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
- 補足説明（idx="1"）→ **内容に応じて以下のいずれかを選択**：
  - **テキスト箇条書き**: 事実の列挙・詳細説明のみの場合
  - **図解（図形＋矢印＋テキストボックス）**: 関係性・フロー・比較がある場合。補足説明プレースホルダーのテキストを空にし、自由配置の図形を追加する
- **スピーカーノート** → 各スライドに必ず作成する。最低でも「話題の言い換え」「メッセージの口頭説明」「補足説明で強調する点」を 3-5 文程度で書く。

#### 図解スライドの作成手順

図解が適切と判断したスライドでは、以下の手順で作成する：

1. 補足説明プレースホルダー（idx="1"）のテキストを空（`<a:p><a:endParaRPr/></a:p>`）にする
2. [references/xml-patterns.md](references/xml-patterns.md) から適切な XML スニペットを選んで `<p:spTree>` 内に追加する
3. よく使う図解パターン：
   - **フロー図**: テキストボックス（ステップ名） → rightArrow → テキストボックス → rightArrow → テキストボックス
   - **ブロック図**: rect 図形を並べて構成要素を表現、矢印で関係性を示す
   - **比較図**: カード枠（rect + テキストボックス）を横に並べる。slide5〜8 を複製する方が早い場合はそちらを使う
   - **強調付き説明**: テキスト箇条書き＋ハイライト枠（黄色 roundRect）で重要部分を囲む
4. 図形の色はテーマカラーを使う：ティール（accent6）を基調、強調は青（accent3）や赤（accent4）

スピーカーノートの書き方は [references/speaker-notes.md](references/speaker-notes.md) を参照。

### 5. スピーカーノート調整

- タイトルスライドにも短い導入ノートを付ける。
- パラグラフスライドでは、見出しを読むだけで終わらず、メッセージの因果関係や補足の読み上げ順を書く。
- 段階表示の複製スライドでは、ノート本文は使い回してよいが、その段で新しく注目させる要素を 1 文追加する。
- Memo バーや黒背景ボックスがある場合は、ノートでも「何を注意喚起する欄か」を明示する。

### 6. clean & pack
```bash
python3 scripts/clean.py unpacked/
python3 scripts/office/pack.py unpacked/ output.pptx --original references/template.pptx
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
