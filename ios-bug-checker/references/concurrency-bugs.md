# 並行処理・Swift Concurrency のバグパターン

## 🔴 Critical

### 1. メインスレッド以外でのUI更新
```swift
// ❌ Bad: バックグラウンドスレッドでUI更新
DispatchQueue.global().async {
    self.label.text = "Updated" // クラッシュまたは未定義動作
}

// ✅ Good: メインスレッドで UI 更新
DispatchQueue.global().async {
    let result = self.processData()
    DispatchQueue.main.async {
        self.label.text = result
    }
}

// ✅ Better (Swift Concurrency)
Task {
    let result = await processData()
    await MainActor.run {
        label.text = result
    }
}
```

**検出パターン**: `DispatchQueue.global()` 内で `.text`, `.image`, `.isHidden` 等のUI操作

### 2. @MainActor 未付与のUI操作メソッド
```swift
// ❌ Bad: async 関数から呼ばれる可能性
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func loadItems() async {
        items = await fetchItems() // メインスレッド保証なし
    }
}

// ✅ Good: @MainActor でマーク
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func loadItems() async {
        items = await fetchItems()
    }
}
```

**検出パターン**: `@Published` があるクラスに `@MainActor` がない

### 3. データ競合（Race Condition）
```swift
// ❌ Bad: 複数スレッドから同時アクセス
var sharedData: [String] = []

DispatchQueue.global().async {
    sharedData.append("A") // 競合!
}
DispatchQueue.global().async {
    sharedData.append("B") // 競合!
}

// ✅ Good: シリアルキューで保護
let queue = DispatchQueue(label: "com.app.data")
queue.async { sharedData.append("A") }
queue.async { sharedData.append("B") }

// ✅ Better: actor で保護
actor DataStore {
    var items: [String] = []
    func append(_ item: String) { items.append(item) }
}
```

---

## 🟠 High

### 4. Sendable 違反（Swift 6）
```swift
// ❌ Bad: 非 Sendable 型を Task 間で共有
class MutableConfig { // Sendable でない
    var value = 0
}

let config = MutableConfig()
Task {
    config.value = 1 // Swift 6 でエラー
}

// ✅ Good: Sendable に準拠
final class Config: Sendable {
    let value: Int
    init(value: Int) { self.value = value }
}

// ✅ Or: actor を使用
actor ConfigActor {
    var value = 0
}
```

**検出パターン**: `Task {` 内で非 `Sendable` クラスのプロパティを変更

### 5. Task のキャンセル未対応
```swift
// ❌ Bad: キャンセルチェックなし
func longProcess() async {
    for i in 0..<100000 {
        await processItem(i) // キャンセルされても続行
    }
}

// ✅ Good: キャンセルチェック
func longProcess() async throws {
    for i in 0..<100000 {
        try Task.checkCancellation()
        await processItem(i)
    }
}
```

### 6. デッドロック
```swift
// ❌ Bad: 同期呼び出しでデッドロック
let queue = DispatchQueue(label: "serial")
queue.sync {
    queue.sync { // デッドロック!
        print("Never reached")
    }
}

// ❌ Bad: メインスレッドでメインへ sync
DispatchQueue.main.sync { // メインスレッドで呼ぶとデッドロック
    print("Deadlock")
}
```

**検出パターン**: `.sync { .* \.sync {` のネスト

---

## 🟡 Medium

### 7. async let の不適切な使用
```swift
// ❌ Bad: 順次実行でメリットなし
let a = await fetchA()
let b = await fetchB()

// ✅ Good: 並行実行
async let a = fetchA()
async let b = fetchB()
let results = await (a, b)
```

### 8. Task 保持の欠如
```swift
// ❌ Bad: Task がすぐにキャンセルされる可能性
func viewDidLoad() {
    Task {
        await loadData() // ViewControllerが解放されると中断
    }
}

// ✅ Good: Task を保持
private var loadTask: Task<Void, Never>?

func viewDidLoad() {
    loadTask = Task {
        await loadData()
    }
}

deinit {
    loadTask?.cancel()
}
```

---

## チェックコマンド

```bash
# Thread Sanitizer でデータ競合検出
xcodebuild test -scheme MyApp -enableThreadSanitizer YES

# Swift 6 strict concurrency チェック
swift build -Xswiftc -strict-concurrency=complete

# Sendable 警告の確認
swift build 2>&1 | grep -i sendable
```

## 関連ツール

- **Thread Sanitizer (TSan)**: ランタイムでデータ競合を検出
- **Swift 6 Strict Concurrency**: コンパイル時に並行処理バグを検出
- **Instruments - System Trace**: スレッド動作の可視化
