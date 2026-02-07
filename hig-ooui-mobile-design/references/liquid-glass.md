# Liquid Glass Design (iOS 26+)

iOS 26で導入されたLiquid Glassデザイン言語。visionOS由来の半透明・屈折・動的反応を持つUI。

## 概要

- **特徴**: 丸みを帯びた半透明要素、リアルなガラスの屈折、動き・コンテンツ・入力に動的に反応
- **適用範囲**: ナビゲーション、コントロール、ボタン、メニュー、ウィジェット
- **原則**: ナビゲーションレイヤーに使用、コンテンツには使用しない

---

## SwiftUI実装

### glassEffect modifier

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, Liquid Glass")
                .padding()
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
```

### 形状のカスタマイズ

```swift
// 角丸四角形
.glassEffect(.regular, in: .rect(cornerRadius: 20))

// カプセル
.glassEffect(.regular, in: .capsule)

// 円形
.glassEffect(.regular, in: .circle)
```

### Tintによる強調

```swift
// プライマリアクション用
Button("Submit") { }
    .glassEffect(.regular.tint(.blue), in: .capsule)

// 危険なアクション
Button("Delete") { }
    .glassEffect(.regular.tint(.red), in: .capsule)
```

### インタラクティブ設定

```swift
// タッチ・ポインター反応を有効化
.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
```

---

## GlassEffectContainer

関連ボタンをグループ化し、近接に応じて自動的にパネルに結合。

```swift
GlassEffectContainer {
    HStack(spacing: 12) {
        Button("Cancel") { }
            .glassEffect(.regular, in: .capsule)
        
        Button("Save") { }
            .glassEffect(.regular.tint(.blue), in: .capsule)
    }
}
```

---

## トランジション

```swift
struct AnimatedCard: View {
    @State private var isExpanded = false
    @Namespace private var glassNamespace
    
    var body: some View {
        VStack {
            if isExpanded {
                ExpandedView()
                    .glassEffectID("card", in: glassNamespace)
            } else {
                CompactView()
                    .glassEffectID("card", in: glassNamespace)
            }
        }
        .glassEffectTransition(.slide)
    }
}
```

---

## ベストプラクティス

| ✅ 推奨                             | ❌ 避ける                 |
| ---------------------------------- | ------------------------ |
| ナビゲーションバー、タブバーに使用 | コンテンツ領域に使用     |
| 1層のみ使用                        | GlassをGlassの上に重ねる |
| プライマリアクションにtint使用     | 全ボタンにtint使用       |
| シンプルな形状を維持               | 複雑なカスタム形状       |

---

## 使用例

### ナビゲーションバー

```swift
struct CustomNavBar: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("Title")
                .font(.headline)
            Spacer()
            Button(action: {}) {
                Image(systemName: "ellipsis")
            }
        }
        .padding()
        .glassEffect(.regular, in: .capsule)
    }
}
```

### フローティングアクションボタン

```swift
struct FloatingButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "plus")
                .font(.title2)
                .padding()
        }
        .glassEffect(.regular.tint(.blue).interactive(), in: .circle)
    }
}
```

### モーダルシート

```swift
struct GlassSheet<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
```

---

## 互換性

| バージョン | 対応                 |
| ---------- | -------------------- |
| iOS 26+    | ✅ ネイティブサポート |
| iOS 25以前 | ⚠️ フォールバック必要 |

```swift
// バージョン分岐
if #available(iOS 26, *) {
    content.glassEffect(.regular, in: .rect(cornerRadius: 16))
} else {
    content
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}
```
