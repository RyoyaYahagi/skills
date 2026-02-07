# Data Persistence

## SwiftData（iOS 17+, 推奨）

### セットアップ

```swift
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var posts: [Post] = []
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
}

@Model
final class Post {
    var id: UUID
    var title: String
    var content: String
    
    @Relationship(inverse: \User.posts)
    var author: User?
    
    init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
    }
}
```

### App設定

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, Post.self])
    }
}
```

### CRUD操作

```swift
struct UserListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \User.createdAt, order: .reverse) private var users: [User]
    
    var body: some View {
        List(users) { user in
            Text(user.name)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        context.delete(user)
                    }
                }
        }
        .toolbar {
            Button("Add") {
                let user = User(name: "New User", email: "new@example.com")
                context.insert(user)
            }
        }
    }
}
```

### フィルタリング

```swift
@Query(
    filter: #Predicate<User> { $0.name.contains("John") },
    sort: \User.createdAt
)
private var filteredUsers: [User]

// 動的フィルタ
struct UserSearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        UserList(searchText: searchText)
    }
}

struct UserList: View {
    @Query private var users: [User]
    
    init(searchText: String) {
        _users = Query(
            filter: #Predicate<User> {
                searchText.isEmpty || $0.name.localizedStandardContains(searchText)
            }
        )
    }
}
```

---

## UserDefaults（設定値）

### PropertyWrapper

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

// 使用
enum Settings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    static var isDarkMode: Bool
    
    @UserDefault(key: "username", defaultValue: "")
    static var username: String
}
```

### @AppStorage（SwiftUI）

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("fontSize") private var fontSize = 14.0
    
    var body: some View {
        Form {
            Toggle("Dark Mode", isOn: $isDarkMode)
            Slider(value: $fontSize, in: 10...30)
        }
    }
}
```

---

## Keychain（認証情報）

```swift
import Security

enum KeychainHelper {
    static func save(_ data: Data, forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    static func load(forKey key: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw KeychainError.loadFailed(status)
        }
        
        return result as? Data
    }
    
    static func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
}
```

---

## FileManager（ファイル保存）

```swift
enum DocumentsManager {
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func save<T: Encodable>(_ object: T, filename: String) throws {
        let url = documentsURL.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url)
    }
    
    static func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let url = documentsURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}
```

---

## 選択ガイド

| 用途           | 推奨                       |
| -------------- | -------------------------- |
| 構造化データ   | SwiftData                  |
| 設定値         | @AppStorage / UserDefaults |
| 認証トークン   | Keychain                   |
| 大きなファイル | FileManager                |
