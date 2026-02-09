# クラッシュ・Optional のバグパターン

## 🔴 Critical

### 1. Force Unwrap（強制アンラップ）
```swift
// ❌ Bad: nil の場合クラッシュ
let value = optionalValue!
let text = dictionary["key"]!

// ✅ Good: 安全なアンラップ
guard let value = optionalValue else { return }
if let text = dictionary["key"] { ... }

// ✅ Or: nil 結合演算子
let text = dictionary["key"] ?? "default"
```

**検出パターン**: 変数に `!` が付いている（`as!`, `try!` も対象）

### 2. Implicitly Unwrapped Optional (@IBOutlet)
```swift
// ❌ Bad: viewDidLoad 前にアクセス
class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        label.text = "Hello" // クラッシュ!
    }
}

// ✅ Good: 適切なタイミングでアクセス
override func viewDidLoad() {
    super.viewDidLoad()
    label.text = "Hello"
}
```

**検出パターン**: `init` またはプロパティ初期化で `@IBOutlet` にアクセス

### 3. 配列の境界外アクセス
```swift
// ❌ Bad: インデックスが範囲外でクラッシュ
let items = [1, 2, 3]
let value = items[5] // クラッシュ!

// ✅ Good: 境界チェック
if items.indices.contains(5) {
    let value = items[5]
}

// ✅ Or: safe subscript 拡張
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
let value = items[safe: 5] // nil
```

**検出パターン**: `array[variable]` でインデックスが動的な場合

### 4. 強制キャスト（as!）
```swift
// ❌ Bad: 型が違うとクラッシュ
let cell = tableView.dequeueReusableCell(...) as! CustomCell

// ✅ Good: 安全なキャスト
guard let cell = tableView.dequeueReusableCell(...) as? CustomCell else {
    return UITableViewCell()
}
```

**検出パターン**: `as!` の使用

---

## 🟠 High

### 5. try! の使用
```swift
// ❌ Bad: 例外でクラッシュ
let data = try! Data(contentsOf: url)
let json = try! JSONDecoder().decode(Model.self, from: data)

// ✅ Good: 適切なエラーハンドリング
do {
    let data = try Data(contentsOf: url)
    let json = try JSONDecoder().decode(Model.self, from: data)
} catch {
    print("Error: \(error)")
}
```

**検出パターン**: `try!` の使用

### 6. fatalError / preconditionFailure の不適切な使用
```swift
// ❌ Bad: プロダクションでクラッシュ
func configure(type: String) {
    switch type {
    case "A": ...
    case "B": ...
    default: fatalError("Unknown type") // リリースでもクラッシュ
    }
}

// ✅ Good: 適切なエラーハンドリング
func configure(type: String) throws {
    switch type {
    case "A": ...
    case "B": ...
    default: throw ConfigError.unknownType(type)
    }
}
```

**検出パターン**: `fatalError`, `preconditionFailure` がデフォルトケースにある

### 7. UserDefaults での型不一致
```swift
// ❌ Bad: 型が違うとクラッシュの可能性
let count = UserDefaults.standard.integer(forKey: "count")
// 以前 string で保存していた場合...

// ✅ Good: 型安全なアプローチ
@propertyWrapper
struct UserDefault<T> {
    private let key: String
    private let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
```

---

## 🟡 Medium

### 8. 未初期化の遅延プロパティ
```swift
// ❌ Bad: 初期化前にアクセスするとクラッシュ
class ViewModel {
    lazy var manager: DataManager = {
        DataManager(config: config) // config が nil だとクラッシュ
    }()
    
    var config: Config!
}

// ✅ Good: 依存順序を明確に
class ViewModel {
    let config: Config
    lazy var manager: DataManager = {
        DataManager(config: config)
    }()
    
    init(config: Config) {
        self.config = config
    }
}
```

### 9. String の範囲操作エラー
```swift
// ❌ Bad: インデックスがずれてクラッシュ
let str = "Hello"
let index = str.index(str.startIndex, offsetBy: 10) // クラッシュ

// ✅ Good: 境界チェック
if let index = str.index(str.startIndex, offsetBy: 10, limitedBy: str.endIndex) {
    let char = str[index]
}
```

---

## 🔵 Low

### 10. guard let での早期リターン忘れ
```swift
// ❌ Bad: コンパイラが検出するがミス
guard let value = optional else {
    print("Error")
    // return を忘れ → コンパイルエラーにはなる
}

// ✅ Good: 確実に return/throw
guard let value = optional else {
    print("Error")
    return
}
```

---

## チェックコマンド

```bash
# Force unwrap の検索
grep -rn "!" --include="*.swift" | grep -v "//" | grep -v "IBOutlet"

# 危険なパターンの検索
grep -rn "as!" --include="*.swift"
grep -rn "try!" --include="*.swift"
grep -rn "fatalError" --include="*.swift"

# クラッシュレポート解析
# Xcode Organizer -> Crashes
```

## 関連ツール

- **Xcode Organizer - Crashes**: クラッシュレポートの確認
- **Firebase Crashlytics**: プロダクションクラッシュ追跡
- **AddressSanitizer (ASan)**: メモリアクセスエラーの検出
