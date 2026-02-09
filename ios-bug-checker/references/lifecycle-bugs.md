# ライフサイクル・状態管理のバグパターン

## 🔴 Critical

### 1. viewDidLoad での非同期処理が完了前にアクセス
```swift
// ❌ Bad: データがロードされる前に UI 更新
class ViewController: UIViewController {
    var data: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData() // 非同期
        tableView.reloadData() // data がまだ空!
    }
}

// ✅ Good: 完了後に UI 更新
override func viewDidLoad() {
    super.viewDidLoad()
    Task {
        data = await loadData()
        tableView.reloadData()
    }
}
```

### 2. deinit での非同期処理
```swift
// ❌ Bad: deinit は self を保持できない
deinit {
    Task {
        await cleanup() // self が既に解放されている可能性
    }
}

// ✅ Good: 同期的にクリーンアップ
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

### 3. SceneDelegate / AppDelegate の状態管理ミス
```swift
// ❌ Bad: バックグラウンド遷移を考慮しない
class DataManager {
    func startSync() { ... }
    // バックグラウンドで同期が継続してクラッシュ
}

// ✅ Good: ライフサイクルイベントで適切に管理
func sceneDidEnterBackground(_ scene: UIScene) {
    dataManager.pauseSync()
}

func sceneWillEnterForeground(_ scene: UIScene) {
    dataManager.resumeSync()
}
```

---

## 🟠 High

### 4. viewWillAppear / viewDidAppear の混同
```swift
// ❌ Bad: viewWillAppear でアニメーション開始
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startAnimation() // ビューがまだ表示されていない
}

// ✅ Good: viewDidAppear でアニメーション
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startAnimation()
}
```

### 5. prepare(for:sender:) での非同期データ渡し
```swift
// ❌ Bad: segue 時にまだデータがない
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? DetailVC {
        vc.data = self.asyncData // まだ nil の可能性
    }
}

// ✅ Good: データが確実にある場合のみ遷移
@IBAction func showDetail() {
    guard let data = asyncData else { return }
    let vc = DetailVC()
    vc.data = data
    navigationController?.pushViewController(vc, animated: true)
}
```

### 6. ObservableObject の循環更新
```swift
// ❌ Bad: 無限ループ
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    var sortedItems: [Item] {
        didSet {
            items = sortedItems // 循環して無限更新!
        }
    }
}

// ✅ Good: 計算プロパティを使用
var sortedItems: [Item] {
    items.sorted { $0.name < $1.name }
}
```

---

## 🟡 Medium

### 7. @StateObject vs @ObservedObject の誤用
```swift
// ❌ Bad: @ObservedObject で所有 → 再生成される
struct ContentView: View {
    @ObservedObject var viewModel = ViewModel() // 毎回生成!
    
    var body: some View { ... }
}

// ✅ Good: @StateObject で所有
struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View { ... }
}

// ✅ Also Good: 親から渡される場合は @ObservedObject
struct ChildView: View {
    @ObservedObject var viewModel: ViewModel // 親が所有
}
```

**検出パターン**: `@ObservedObject var .* = .*()` でインライン初期化

### 8. View の更新頻度過多
```swift
// ❌ Bad: 毎秒更新で CPU 負荷
struct TimerView: View {
    @State private var time = Date()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(time.formatted())
            .onReceive(timer) { time = $0 } // 100回/秒!
    }
}

// ✅ Good: 適切な更新間隔
let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
```

### 9. ViewController の retain cycle（Modal dismissed but alive）
```swift
// ❌ Bad: dismiss 後も VC が生きている
class ParentVC: UIViewController {
    var childVC: ChildVC?
    
    func showChild() {
        childVC = ChildVC()
        childVC?.onComplete = {
            self.updateUI() // strong reference
        }
        present(childVC!, animated: true)
    }
}

// ✅ Good: weak self でキャプチャ
childVC?.onComplete = { [weak self] in
    self?.updateUI()
}
```

---

## 🔵 Low

### 10. viewDidLoad での重い処理
```swift
// ❌ Bad: 起動が遅くなる
override func viewDidLoad() {
    super.viewDidLoad()
    let data = loadLargeData() // 同期で重い処理
    configure(with: data)
}

// ✅ Good: 非同期で読み込み
override func viewDidLoad() {
    super.viewDidLoad()
    showLoadingIndicator()
    Task {
        let data = await loadLargeData()
        configure(with: data)
        hideLoadingIndicator()
    }
}
```

### 11. @Environment の誤った仮定
```swift
// ❌ Bad: Environment が nil だと問題
struct ContentView: View {
    @Environment(\.myDependency) var dependency
    
    func doSomething() {
        dependency.action() // dependency が nil だとクラッシュ（カスタム @Environment）
    }
}

// ✅ Good: デフォルト値を設定
extension EnvironmentValues {
    var myDependency: MyDependency {
        get { self[MyDependencyKey.self] }
        set { self[MyDependencyKey.self] = newValue }
    }
}

private struct MyDependencyKey: EnvironmentKey {
    static let defaultValue = MyDependency() // デフォルト値
}
```

---

## チェックコマンド

```bash
# @ObservedObject のインライン初期化を検索
grep -rn "@ObservedObject.*=.*(" --include="*.swift"

# deinit での非同期処理を検索
grep -A5 "deinit {" --include="*.swift" | grep -E "Task|async|await"

# viewWillAppear でのアニメーション
grep -A10 "viewWillAppear" --include="*.swift" | grep -E "animate|animation"
```

## 関連ツール

- **Xcode View Hierarchy Debugger**: View の状態を確認
- **Instruments - SwiftUI**: View の更新頻度を追跡
- **Memory Graph Debugger**: オブジェクトの生存確認
