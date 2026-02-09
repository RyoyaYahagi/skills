# メモリ・参照サイクルのバグパターン

## 🔴 Critical

### 1. クロージャでの循環参照
```swift
// ❌ Bad: selfがキャプチャされ解放されない
class ViewController: UIViewController {
    var completion: (() -> Void)?
    
    func setup() {
        completion = {
            self.doSomething() // 強参照
        }
    }
}

// ✅ Good: [weak self] でキャプチャ
completion = { [weak self] in
    self?.doSomething()
}
```

**検出パターン**: `{` の後に `[weak self]` なしで `self.` が出現

### 2. delegate の強参照
```swift
// ❌ Bad: delegate が strong だと循環参照
protocol MyDelegate: AnyObject {}
class Manager {
    var delegate: MyDelegate? // strong!
}

// ✅ Good: weak にする
weak var delegate: MyDelegate?
```

**検出パターン**: `protocol.*Delegate` 定義で `var delegate:` が `weak` でない

### 3. NotificationCenter の未解除
```swift
// ❌ Bad: removeObserver しない
override func viewDidLoad() {
    NotificationCenter.default.addObserver(self, ...)
}
// deinit で解除忘れ

// ✅ Good: deinit で確実に解除
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

**検出パターン**: `addObserver` があるが `removeObserver` がない

---

## 🟠 High

### 4. Timer の強参照
```swift
// ❌ Bad: Timer は target を強参照
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.update() // 循環参照
}

// ✅ Good: [weak self] + invalidate
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.update()
}
// deinit で timer?.invalidate()
```

### 5. DispatchWorkItem のキャプチャ
```swift
// ❌ Bad: workItem がキャンセルされないと解放されない
let workItem = DispatchWorkItem {
    self.process()
}

// ✅ Good: weak self + cancel 管理
let workItem = DispatchWorkItem { [weak self] in
    self?.process()
}
```

---

## 🟡 Medium

### 6. 画像キャッシュの肥大化
```swift
// ❌ Bad: 無制限のメモリ使用
var imageCache: [String: UIImage] = [:]

// ✅ Good: NSCache で自動解放
let imageCache = NSCache<NSString, UIImage>()
imageCache.countLimit = 100
```

### 7. 大きな配列の保持
```swift
// ❌ Bad: メモリを長時間占有
class DataManager {
    var allRecords: [LargeObject] = [] // 数万件
}

// ✅ Good: ページネーション or lazy loading
func loadPage(_ page: Int) -> [LargeObject]
```

---

## チェックコマンド

```bash
# Instruments で Memory Leak 検出
xcrun swift -I <sdk-path> instruments -t Leaks <app-bundle>

# 循環参照の静的解析
grep -rn "var delegate:" --include="*.swift" | grep -v "weak"
grep -rn "{ \[" --include="*.swift" | grep -v "weak self"
```

## 関連ツール

- **Xcode Memory Graph Debugger**: ランタイムでオブジェクトグラフを可視化
- **Instruments - Leaks**: メモリリーク検出
- **Instruments - Allocations**: メモリ割り当て追跡
