# iOS Architecture Patterns

## MVVM（Model-View-ViewModel）

### 基本構成

```
App/
├── Models/
│   └── User.swift
├── ViewModels/
│   └── UserViewModel.swift
├── Views/
│   └── UserView.swift
├── Services/
│   └── UserService.swift
└── Repositories/
    └── UserRepository.swift
```

### ViewModel（@Observable）

```swift
// ViewModels/UserViewModel.swift
import SwiftUI

@Observable
final class UserViewModel {
    private let repository: UserRepository
    
    var users: [User] = []
    var isLoading = false
    var error: Error?
    
    init(repository: UserRepository = .init()) {
        self.repository = repository
    }
    
    func fetchUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            users = try await repository.fetchUsers()
        } catch {
            self.error = error
        }
    }
    
    func deleteUser(_ user: User) async {
        do {
            try await repository.delete(user)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = error
        }
    }
}
```

### View

```swift
// Views/UserListView.swift
import SwiftUI

struct UserListView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.users) { user in
                        UserRow(user: user)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    Task { await viewModel.deleteUser(user) }
                                }
                            }
                    }
                }
            }
            .navigationTitle("Users")
            .task { await viewModel.fetchUsers() }
        }
    }
}
```

### Repository

```swift
// Repositories/UserRepository.swift
protocol UserRepositoryProtocol {
    func fetchUsers() async throws -> [User]
    func delete(_ user: User) async throws
}

final class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient
    private let cache: UserCache
    
    init(apiClient: APIClient = .shared, cache: UserCache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }
    
    func fetchUsers() async throws -> [User] {
        if let cached = cache.getUsers() {
            return cached
        }
        let users = try await apiClient.request(UserEndpoint.list)
        cache.save(users)
        return users
    }
    
    func delete(_ user: User) async throws {
        try await apiClient.request(UserEndpoint.delete(user.id))
        cache.remove(user)
    }
}
```

---

## TCA（The Composable Architecture）

### セットアップ

```swift
// Package.swift
.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
```

### Feature（Reducer）

```swift
import ComposableArchitecture

@Reducer
struct UsersFeature {
    @ObservableState
    struct State: Equatable {
        var users: [User] = []
        var isLoading = false
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action {
        case onAppear
        case usersResponse(Result<[User], Error>)
        case deleteUser(User)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case confirmDelete(User)
        }
    }
    
    @Dependency(\.userClient) var userClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.usersResponse(Result {
                        try await userClient.fetch()
                    }))
                }
                
            case let .usersResponse(.success(users)):
                state.isLoading = false
                state.users = users
                return .none
                
            case let .usersResponse(.failure(error)):
                state.isLoading = false
                state.alert = AlertState { TextState("Error: \(error.localizedDescription)") }
                return .none
                
            case let .deleteUser(user):
                state.users.removeAll { $0.id == user.id }
                return .run { _ in
                    try await userClient.delete(user.id)
                }
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
```

### View（TCA）

```swift
struct UsersView: View {
    @Bindable var store: StoreOf<UsersFeature>
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                } else {
                    List(store.users) { user in
                        Text(user.name)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    store.send(.deleteUser(user))
                                }
                            }
                    }
                }
            }
            .navigationTitle("Users")
            .onAppear { store.send(.onAppear) }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}
```

---

## MV（Model-View）シンプルアプリ向け

小規模アプリでは@Observableモデルを直接使用。

```swift
@Observable
final class AppModel {
    var users: [User] = []
    var selectedUser: User?
    
    private let repository = UserRepository()
    
    func loadUsers() async {
        users = (try? await repository.fetchUsers()) ?? []
    }
}

struct ContentView: View {
    @State private var model = AppModel()
    
    var body: some View {
        List(model.users) { user in
            Text(user.name)
        }
        .task { await model.loadUsers() }
    }
}
```

---

## 選択ガイド

| パターン | 適用場面                                     |
| -------- | -------------------------------------------- |
| **MV**   | プロトタイプ、1-5画面の小規模アプリ          |
| **MVVM** | 中規模アプリ、チーム開発、テスタビリティ重視 |
| **TCA**  | 大規模アプリ、複雑な状態管理、厳密なテスト   |
