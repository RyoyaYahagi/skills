# Networking

## URLSession + async/await

### 基本構成

```swift
// APIClient.swift
actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try endpoint.urlRequest()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.httpError(httpResponse.statusCode, data)
        }
        
        return try decoder.decode(T.self, from: data)
    }
}
```

### Endpoint定義

```swift
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
}

extension Endpoint {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var headers: [String: String] { ["Content-Type": "application/json"] }
    var body: Data? { nil }
    
    func urlRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}
```

### 具体的なEndpoint

```swift
enum UserEndpoint: Endpoint {
    case list
    case get(id: String)
    case create(User)
    case update(User)
    case delete(id: String)
    
    var path: String {
        switch self {
        case .list: "/users"
        case .get(let id), .delete(let id): "/users/\(id)"
        case .create: "/users"
        case .update(let user): "/users/\(user.id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .list, .get: .GET
        case .create: .POST
        case .update: .PUT
        case .delete: .DELETE
        }
    }
    
    var body: Data? {
        switch self {
        case .create(let user), .update(let user):
            try? JSONEncoder().encode(user)
        default:
            nil
        }
    }
}
```

### 使用例

```swift
func fetchUsers() async throws -> [User] {
    try await APIClient.shared.request(UserEndpoint.list)
}

func createUser(_ user: User) async throws -> User {
    try await APIClient.shared.request(UserEndpoint.create(user))
}
```

---

## 認証付きリクエスト

```swift
actor AuthenticatedAPIClient {
    private let apiClient = APIClient.shared
    private var accessToken: String?
    
    func setToken(_ token: String) {
        self.accessToken = token
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var modifiedEndpoint = endpoint
        if let token = accessToken {
            modifiedEndpoint.headers["Authorization"] = "Bearer \(token)"
        }
        return try await apiClient.request(modifiedEndpoint)
    }
}
```

---

## エラーハンドリング

```swift
enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int, Data)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid response"
        case .httpError(let code, _): "HTTP Error: \(code)"
        case .decodingError(let error): "Decoding error: \(error.localizedDescription)"
        case .networkError(let error): "Network error: \(error.localizedDescription)"
        }
    }
}
```

---

## キャッシュ

```swift
actor ResponseCache {
    private var cache: [String: (data: Data, expiry: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5分
    
    func get(_ key: String) -> Data? {
        guard let entry = cache[key], entry.expiry > Date() else {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }
    
    func set(_ key: String, data: Data) {
        cache[key] = (data, Date().addingTimeInterval(ttl))
    }
}
```

---

## Retry + Exponential Backoff

```swift
extension APIClient {
    func requestWithRetry<T: Decodable>(
        _ endpoint: Endpoint,
        maxRetries: Int = 3
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await request(endpoint)
            } catch {
                lastError = error
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(for: .seconds(delay))
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
}
```
