# UI・レイアウトのバグパターン

## 🔴 Critical

### 1. Auto Layout 制約の競合
```swift
// ❌ Bad: 制約が競合
view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    view.widthAnchor.constraint(equalToConstant: 100),
    view.widthAnchor.constraint(equalToConstant: 200) // 競合!
])

// ✅ Good: 一貫した制約
NSLayoutConstraint.activate([
    view.widthAnchor.constraint(equalToConstant: 100)
])
```

**検出パターン**: 同じアンカーに複数の制約が設定

### 2. translatesAutoresizingMaskIntoConstraints 未設定
```swift
// ❌ Bad: プログラムで制約を追加するのに true のまま
let view = UIView()
// translatesAutoresizingMaskIntoConstraints = true (デフォルト)
parent.addSubview(view)
NSLayoutConstraint.activate([...]) // 競合する

// ✅ Good: false に設定
let view = UIView()
view.translatesAutoresizingMaskIntoConstraints = false
parent.addSubview(view)
```

**検出パターン**: `addSubview` + `NSLayoutConstraint.activate` があるが `translatesAutoresizingMaskIntoConstraints = false` がない

---

## 🟠 High

### 3. Safe Area 無視
```swift
// ❌ Bad: ノッチやホームインジケータを無視
NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: parent.topAnchor)
])

// ✅ Good: Safe Area を尊重
NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor)
])
```

**検出パターン**: `topAnchor.constraint(equalTo:.*\.topAnchor)` で `safeAreaLayoutGuide` なし

### 4. Dark Mode 未対応
```swift
// ❌ Bad: ハードコードされた色
view.backgroundColor = UIColor.white
label.textColor = UIColor.black

// ✅ Good: セマンティックカラー
view.backgroundColor = .systemBackground
label.textColor = .label
```

**検出パターン**: `UIColor.white`, `UIColor.black`, `#FFFFFF`, `#000000` のハードコード

### 5. Dynamic Type 未対応
```swift
// ❌ Bad: 固定フォントサイズ
label.font = UIFont.systemFont(ofSize: 16)

// ✅ Good: Dynamic Type 対応
label.font = .preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true
```

**検出パターン**: `UIFont.systemFont(ofSize:` の使用

---

## 🟡 Medium

### 6. SwiftUI - @State の不適切な初期化
```swift
// ❌ Bad: init で @State を直接設定
struct ContentView: View {
    @State private var text: String
    
    init(initialText: String) {
        text = initialText // 警告: @State should not be used here
    }
}

// ✅ Good: _text で初期化
init(initialText: String) {
    _text = State(initialValue: initialText)
}
```

### 7. SwiftUI - 過剰な body 再計算
```swift
// ❌ Bad: 計算が毎回実行される
var body: some View {
    let filtered = items.filter { $0.isActive } // 毎回実行
    List(filtered) { ... }
}

// ✅ Good: computed property または @State/@StateObject
@State private var filteredItems: [Item] = []

var body: some View {
    List(filteredItems) { ... }
        .onAppear { filteredItems = items.filter { $0.isActive } }
}
```

### 8. キーボード回避の未対応
```swift
// ❌ Bad: キーボードに隠れる入力フィールド
TextField("入力", text: $text)

// ✅ Good: ScrollView + キーボード回避
ScrollView {
    TextField("入力", text: $text)
}
.scrollDismissesKeyboard(.interactively)

// UIKit: Keyboard Notification で調整
NotificationCenter.default.addObserver(
    self, selector: #selector(keyboardWillShow),
    name: UIResponder.keyboardWillShowNotification, object: nil)
```

---

## 🔵 Low

### 9. 画像アスペクト比の無視
```swift
// ❌ Bad: 画像が歪む
imageView.contentMode = .scaleToFill

// ✅ Good: アスペクト比を保持
imageView.contentMode = .scaleAspectFit
// または
imageView.contentMode = .scaleAspectFill
imageView.clipsToBounds = true
```

### 10. Accessibility 未対応
```swift
// ❌ Bad: VoiceOver で読み上げられない
imageView.image = UIImage(named: "icon")

// ✅ Good: アクセシビリティラベル設定
imageView.isAccessibilityElement = true
imageView.accessibilityLabel = "設定アイコン"
```

---

## チェックコマンド

```bash
# 制約の競合をログで確認
# Info.plist に追加: UIViewLayoutFeedbackLoopDebuggingThreshold = 100

# Dark Mode 非対応色の検索
grep -rn "UIColor\.(white\|black)" --include="*.swift"
grep -rn "#FFFFFF\|#000000" --include="*.swift"

# 固定フォントサイズの検索
grep -rn "systemFont(ofSize:" --include="*.swift"
```

## 関連ツール

- **Accessibility Inspector**: アクセシビリティ問題の検出
- **View Hierarchy Debugger**: レイアウト問題の可視化
- **Override User Interface Style**: Dark Mode テスト
