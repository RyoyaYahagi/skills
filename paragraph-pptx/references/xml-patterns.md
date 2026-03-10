# パラグラフテンプレート XMLパターン集

template.pptx の編集時に使えるコピペ可能な XML スニペット。
すべて unpacked 後の slide XML 内で使用する。

---

## 基本：パラグラフスライドのプレースホルダー編集

### 話題ヘッダー（idx="11"）のテキスト変更

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="4" name="テキスト プレースホルダー 3">
      <!-- extLst省略 -->
    </p:cNvPr>
    <p:cNvSpPr>
      <a:spLocks noGrp="1"/>
    </p:cNvSpPr>
    <p:nvPr>
      <p:ph type="body" sz="quarter" idx="11"/>
    </p:nvPr>
  </p:nvSpPr>
  <p:spPr/>
  <p:txBody>
    <a:bodyPr>
      <a:normAutofit/>
    </a:bodyPr>
    <a:lstStyle/>
    <a:p>
      <a:r>
        <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
        <a:t>ここに話題を書く</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

### メッセージ（type="title"）のテキスト変更

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="2" name="タイトル 1">
      <!-- extLst省略 -->
    </p:cNvPr>
    <p:cNvSpPr>
      <a:spLocks noGrp="1"/>
    </p:cNvSpPr>
    <p:nvPr>
      <p:ph type="title"/>
    </p:nvPr>
  </p:nvSpPr>
  <p:spPr/>
  <p:txBody>
    <a:bodyPr/>
    <a:lstStyle/>
    <a:p>
      <a:r>
        <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
        <a:t>ここにメッセージを書く</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

### 補足説明（idx="1"）の箇条書き

```xml
<p:txBody>
  <a:bodyPr/>
  <a:lstStyle/>
  <!-- レベル1箇条書き -->
  <a:p>
    <a:pPr lvl="0"/>
    <a:r>
      <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
      <a:t>第1レベルの項目</a:t>
    </a:r>
  </a:p>
  <!-- レベル2箇条書き -->
  <a:p>
    <a:pPr lvl="1"/>
    <a:r>
      <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
      <a:t>第2レベルの項目</a:t>
    </a:r>
  </a:p>
</p:txBody>
```

---

## テキストボックス（自由配置）

プレースホルダー外にテキストを配置する場合。
座標 (x, y) と寸法 (cx, cy) は EMU 単位。

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="100" name="テキスト ボックス 99"/>
    <p:cNvSpPr txBox="1"/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="419100" y="2000000"/>
      <a:ext cx="4000000" cy="500000"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
    <a:noFill/>
  </p:spPr>
  <p:txBody>
    <a:bodyPr wrap="square" rtlCol="0">
      <a:spAutoFit/>
    </a:bodyPr>
    <a:lstStyle/>
    <a:p>
      <a:r>
        <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" sz="1800" b="1" dirty="0">
          <a:solidFill>
            <a:schemeClr val="bg1">
              <a:lumMod val="10000"/>
            </a:schemeClr>
          </a:solidFill>
          <a:latin typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>
          <a:ea typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>
        </a:rPr>
        <a:t>テキスト内容</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

---

## ハイライト枠（黄色 roundRect）

注目箇所を囲む透明な黄色枠。アニメーション代わりの段階表示で使用。

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="200" name="ハイライト枠 199"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="450000" y="1070000"/>
      <a:ext cx="4080000" cy="2180000"/>
    </a:xfrm>
    <a:prstGeom prst="roundRect">
      <a:avLst/>
    </a:prstGeom>
    <a:noFill/>
    <a:ln w="57150">
      <a:solidFill>
        <a:srgbClr val="FFFF00"/>
      </a:solidFill>
    </a:ln>
  </p:spPr>
  <p:style>
    <a:lnRef idx="2">
      <a:schemeClr val="accent1">
        <a:shade val="15000"/>
      </a:schemeClr>
    </a:lnRef>
    <a:fillRef idx="1">
      <a:schemeClr val="accent1"/>
    </a:fillRef>
    <a:effectRef idx="0">
      <a:schemeClr val="accent1"/>
    </a:effectRef>
    <a:fontRef idx="minor">
      <a:schemeClr val="tx1"/>
    </a:fontRef>
  </p:style>
  <p:txBody>
    <a:bodyPr rtlCol="0" anchor="ctr"/>
    <a:lstStyle/>
    <a:p>
      <a:endParaRPr kumimoji="1" lang="ja-JP" altLang="en-US"/>
    </a:p>
  </p:txBody>
</p:sp>
```

**使い方**: `<a:off>` の x, y と `<a:ext>` の cx, cy を囲みたい領域に合わせて調整する。

---

## Memo バー

スライド下部に配置する注記欄。Memoラベル（ティール背景） + テキストボックスの2要素で構成。

### Memo ラベル（ティール背景ボックス）

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="300" name="Memoラベル 299"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="756781" y="6290030"/>
      <a:ext cx="968938" cy="440267"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
  </p:spPr>
  <p:style>
    <a:lnRef idx="1">
      <a:schemeClr val="accent6"/>
    </a:lnRef>
    <a:fillRef idx="3">
      <a:schemeClr val="accent6"/>
    </a:fillRef>
    <a:effectRef idx="2">
      <a:schemeClr val="accent6"/>
    </a:effectRef>
    <a:fontRef idx="minor">
      <a:schemeClr val="lt1"/>
    </a:fontRef>
  </p:style>
  <p:txBody>
    <a:bodyPr rtlCol="0" anchor="ctr"/>
    <a:lstStyle/>
    <a:p>
      <a:pPr algn="ctr"/>
      <a:r>
        <a:rPr kumimoji="1" lang="en-US" altLang="ja-JP" dirty="0"/>
        <a:t>Memo </a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

### Memo テキストボックス

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="301" name="Memoテキスト 300"/>
    <p:cNvSpPr txBox="1"/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="1725719" y="6340829"/>
      <a:ext cx="7023762" cy="369332"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
    <a:noFill/>
  </p:spPr>
  <p:txBody>
    <a:bodyPr wrap="square" rtlCol="0">
      <a:spAutoFit/>
    </a:bodyPr>
    <a:lstStyle/>
    <a:p>
      <a:r>
        <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
        <a:t>ここに補足メモを書く</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

---

## 黒背景ボックス（課題・デメリット表示）

カードの下部に重ねて配置し、白テキストで課題点を表示する。

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="400" name="課題ボックス 399"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="450000" y="3500000"/>
      <a:ext cx="4000000" cy="700000"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
    <a:solidFill>
      <a:srgbClr val="000000"/>
    </a:solidFill>
    <a:ln>
      <a:noFill/>
    </a:ln>
  </p:spPr>
  <p:txBody>
    <a:bodyPr wrap="square" rtlCol="0" anchor="ctr"/>
    <a:lstStyle/>
    <a:p>
      <a:pPr marL="342900" indent="-342900">
        <a:buFont typeface="Wingdings" panose="05000000000000000000" pitchFamily="2" charset="2"/>
        <a:buChar char="l"/>
      </a:pPr>
      <a:r>
        <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" sz="1600" dirty="0">
          <a:solidFill>
            <a:srgbClr val="FFFFFF"/>
          </a:solidFill>
          <a:latin typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>
          <a:ea typeface="游ゴシック" panose="020B0400000000000000" pitchFamily="50" charset="-128"/>
        </a:rPr>
        <a:t>課題点のテキスト</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

---

## カード枠（テンプレートの角丸矩形カード）

3カード・4カードレイアウトで使うカード枠。テンプレートの slide5〜8 を複製した場合は既存の矩形を編集するだけでよい。
新規にカードを追加する場合は以下を使用。

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="500" name="カード枠 499"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="353453" y="2353132"/>
      <a:ext cx="2737005" cy="3466643"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
    <a:noFill/>
    <a:ln w="19050">
      <a:solidFill>
        <a:schemeClr val="bg2">
          <a:lumMod val="75000"/>
        </a:schemeClr>
      </a:solidFill>
    </a:ln>
  </p:spPr>
  <p:txBody>
    <a:bodyPr rtlCol="0" anchor="ctr"/>
    <a:lstStyle/>
    <a:p>
      <a:endParaRPr kumimoji="1" lang="ja-JP" altLang="en-US"/>
    </a:p>
  </p:txBody>
</p:sp>
```

### 3カード配置の座標

| カード | x | y | cx | cy |
|--------|---|---|----|----|
| 左 | 353453 | 2353132 | 2737005 | 3466643 |
| 中 | 3236033 | 2348085 | 2737005 | 3466643 |
| 右 | 6098954 | 2353132 | 2737005 | 3466643 |

### カード見出しテキストボックスの座標

各カード枠内の上部に配置する見出しテキスト。

| カード | x | y | 備考 |
|--------|---|---|------|
| 左 | 398445 | 2362198 | カード枠の少し内側 |
| 中 | 3268579 | 2360028 | |
| 右 | 6152016 | 2360028 | |

---

## 色付きテキスト（強調）

本文中の一部を色付きにする場合、`<a:r>` を分割して色指定する。

```xml
<a:p>
  <a:r>
    <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
    <a:t>通常テキスト</a:t>
  </a:r>
  <a:r>
    <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0">
      <a:solidFill>
        <a:srgbClr val="FF0000"/>
      </a:solidFill>
    </a:rPr>
    <a:t>赤い強調テキスト</a:t>
  </a:r>
  <a:r>
    <a:rPr kumimoji="1" lang="ja-JP" altLang="en-US" dirty="0"/>
    <a:t>の続き</a:t>
  </a:r>
</a:p>
```

---

## 矢印図形

フロー図などで使う矢印。

```xml
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="600" name="矢印 599"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    <a:xfrm>
      <a:off x="4000000" y="3000000"/>
      <a:ext cx="1200000" cy="600000"/>
    </a:xfrm>
    <a:prstGeom prst="rightArrow">
      <a:avLst/>
    </a:prstGeom>
    <a:solidFill>
      <a:schemeClr val="accent6"/>
    </a:solidFill>
    <a:ln>
      <a:noFill/>
    </a:ln>
  </p:spPr>
  <p:txBody>
    <a:bodyPr rtlCol="0" anchor="ctr"/>
    <a:lstStyle/>
    <a:p>
      <a:pPr algn="ctr"/>
      <a:endParaRPr kumimoji="1" lang="ja-JP" altLang="en-US"/>
    </a:p>
  </p:txBody>
</p:sp>
```

他の矢印形状: `leftArrow`, `upArrow`, `downArrow`, `leftRightArrow`, `bentArrow`, `chevron`

---

## 画像の配置

画像ファイルを配置する場合、まず画像を `ppt/media/` に配置し、スライドの `.rels` にリレーションを追加する。

### スライドXML内の画像要素

```xml
<p:pic>
  <p:nvPicPr>
    <p:cNvPr id="700" name="図 699"/>
    <p:cNvPicPr>
      <a:picLocks noChangeAspect="1"/>
    </p:cNvPicPr>
    <p:nvPr/>
  </p:nvPicPr>
  <p:blipFill>
    <a:blip r:embed="rId2"/>
    <a:stretch>
      <a:fillRect/>
    </a:stretch>
  </p:blipFill>
  <p:spPr>
    <a:xfrm>
      <a:off x="500000" y="2000000"/>
      <a:ext cx="3000000" cy="2000000"/>
    </a:xfrm>
    <a:prstGeom prst="rect">
      <a:avLst/>
    </a:prstGeom>
  </p:spPr>
</p:pic>
```

### .rels ファイルへの追加

`ppt/slides/_rels/slideN.xml.rels` に以下を追加：

```xml
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/imageN.png"/>
```

---

## ID の採番ルール

- スライド内の要素 `id` は、そのスライド内で一意であればよい
- 既存の最大 id + 1 で採番する
- リレーション `rId` も同様にスライドの .rels 内で一意に採番する
