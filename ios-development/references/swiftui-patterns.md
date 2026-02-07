# SwiftUI Patterns

## 状態管理

### @State（ローカル状態）

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("\(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

### @Binding（親子間）

```swift
struct ParentView: View {
    @State private var isOn = false
    
    var body: some View {
        ToggleView(isOn: $isOn)
    }
}

struct ToggleView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("Toggle", isOn: $isOn)
    }
}
```

### @Observable（iOS 17+）

```swift
@Observable
class UserSettings {
    var username = ""
    var notifications = true
}

struct SettingsView: View {
    @State private var settings = UserSettings()
    
    var body: some View {
        Form {
            TextField("Username", text: $settings.username)
            Toggle("Notifications", isOn: $settings.notifications)
        }
    }
}
```

### @Environment（依存注入）

```swift
// 環境値定義
@Observable
class AppState {
    var user: User?
    var theme: Theme = .system
}

extension EnvironmentValues {
    @Entry var appState = AppState()
}

// 使用
struct RootView: View {
    @State private var appState = AppState()
    
    var body: some View {
        ContentView()
            .environment(\.appState, appState)
    }
}

struct ProfileView: View {
    @Environment(\.appState) private var appState
    
    var body: some View {
        Text(appState.user?.name ?? "Guest")
    }
}
```

---

## コンポーネントパターン

### ViewBuilderコンポーネント

```swift
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 使用
Card {
    VStack {
        Text("Title")
        Text("Subtitle")
    }
}
```

### ViewModifier

```swift
struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content.opacity(isLoading ? 0.5 : 1)
            if isLoading {
                ProgressView()
            }
        }
        .disabled(isLoading)
    }
}

extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// 使用
ContentView().loading(viewModel.isLoading)
```

---

## ナビゲーション

### NavigationStack + NavigationPath

```swift
@Observable
class Router {
    var path = NavigationPath()
    
    func push(_ destination: Destination) {
        path.append(destination)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum Destination: Hashable {
    case detail(User)
    case settings
}

struct RootView: View {
    @State private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ListView()
                .navigationDestination(for: Destination.self) { dest in
                    switch dest {
                    case .detail(let user): UserDetailView(user: user)
                    case .settings: SettingsView()
                    }
                }
        }
        .environment(router)
    }
}
```

### Sheet / FullScreenCover

```swift
struct ContentView: View {
    @State private var showSettings = false
    @State private var selectedUser: User?
    
    var body: some View {
        Button("Settings") { showSettings = true }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $selectedUser) { user in
                UserDetailView(user: user)
            }
    }
}
```

---

## 非同期処理

### .task modifier

```swift
struct UserListView: View {
    @State private var users: [User] = []
    
    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            users = await fetchUsers()
        }
        .refreshable {
            users = await fetchUsers()
        }
    }
}
```

### TaskGroup（並列処理）

```swift
func loadData() async {
    await withTaskGroup(of: Void.self) { group in
        group.addTask { await loadUsers() }
        group.addTask { await loadPosts() }
        group.addTask { await loadSettings() }
    }
}
```

---

## アニメーション

```swift
struct AnimatedButton: View {
    @State private var isPressed = false
    
    var body: some View {
        Button("Tap me") { }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}
```

### withAnimation

```swift
Button("Toggle") {
    withAnimation(.spring) {
        isExpanded.toggle()
    }
}
```
