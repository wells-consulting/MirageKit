# MirageKit

![Desert Mirage](Assets/mirage_header.jpeg)

A Swift toolkit for Apple-platform apps providing networking, JSON coding, URL building, keychain storage, logging, and common Foundation extensions.

## Requirements

- Swift 6.2+
- iOS 18+ / macOS 15+ / watchOS 9+ / tvOS 18+

## Installation

Add MirageKit as a Swift Package Manager dependency:

```swift
dependencies: [
    .package(url: "https://github.com/<owner>/MirageKit.git", from: "1.0.0"),
]
```

Then add `"MirageKit"` to the target's `dependencies` array.

## Modules

### Labrador — HTTP Client

An actor-based HTTP client built on `URLSession` with typed responses, automatic JSON coding, interceptors, retry policies, and TLS trust configuration.

```swift
let client = Labrador(configuration: .init(
    baseURL: URL(string: "https://api.example.com")!,
    logOptions: .logAll,
    retryPolicy: .init(maxRetries: 2),
))

// GET with automatic JSON decoding
let users: [User] = try await client.get(url, as: [User].self)

// POST with Encodable body
try await client.post(url, body: newUser)

// Response variant — access headers and status code
let response = try await client.getWithResponse(url, as: User.self)
print(response.statusCode, response.header("X-Request-Id") ?? "")
```

**Key features:**

- Methods for GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- `Response<T>` variants that expose HTTP metadata alongside decoded values
- `MultipartForm` and `URLEncodedForm` body types
- File upload/download with progress tracking
- `Interceptor` chain for request/response modification (e.g. token refresh)
- `RetryPolicy` with constant or exponential backoff
- `TLSTrustPolicy` — `.system` (default) or `.trustSelfSigned`
- `BaseURL` support with path resolution
- Configurable cache policy, timeout, and log verbosity

### Jayson — JSON Coder

A thin wrapper around `JSONEncoder`/`JSONDecoder` with sensible defaults (ISO 8601 dates, JSON5 decoding, sorted keys) and structured error reporting.

```swift
let jayson = Jayson.shared

let data = try jayson.encode(user)
let user = try jayson.decode(User.self, from: data)
let json = try jayson.string(from: user)

// Non-throwing stringify
let optionalString = jayson.stringify(user)
```

Custom configuration:

```swift
let jayson = Jayson(configuration: .init(
    keyEncodingStrategy: .convertToSnakeCase,
    keyDecodingStrategy: .convertFromSnakeCase,
))
```

### Earl — URL Builder

A chainable builder for constructing URLs with type-safe query parameters.

```swift
let url = try Earl("https://api.example.com/v1")
    .path("users")
    .query("active", true)
    .query("page", 1)
    .query("since", Date())
    .build()
// https://api.example.com/v1/users?active=true&page=1&since=2026-03-13T...
```

Supports `Bool`, `Int`, `Int32`, `Int64`, `Float`, `Double`, `Decimal`, `String`, `UUID`, and `Date` query parameters. Nil optionals are silently skipped.

### Keeper — Keychain Store

A `Sendable` struct for secure key-value storage backed by the system keychain (Apple platforms only).

```swift
let keeper = Keeper()

try keeper.save(credentials, forKey: "user_credentials")
let credentials = try keeper.load(Credentials.self, forKey: "user_credentials")
try keeper.delete(key: "user_credentials")
```

Items are stored as `kSecClassGenericPassword` entries. Values are encoded/decoded with Jayson, so any `Codable` type works. Supports optional access groups for keychain sharing.

### Timber — Logger

A platform-agnostic logger that wraps `os.Logger` on Apple platforms and falls back to `print` elsewhere. Accepts regular `String` messages (not just string literals).

```swift
let log = Timber(subsystem: "MyApp", category: "Network")
log.debug("Request started")
log.error(error, while: "fetching users")
```

**Log persistence** (Apple platforms): wire up a `TimberLogStore` to persist entries at or above a minimum severity to a rotating JSONL file (500 entries, 7-day max age).

```swift
// At app startup
Timber.enableLogStore(minimumLevel: .error)

// Read entries later
let entries = await TimberLogStore.shared.entries
await TimberLogStore.shared.deleteAll()
```

**Sink**: set `Timber.sink` to forward every log message to external storage or analytics.

### Foundation Extensions

Lightweight extensions on standard library and Foundation types:

| File | Highlights |
|---|---|
| `Array+CoreExtensions` | Safe subscript, grouping, chunking |
| `Bundle+CoreExtensions` | `appName`, `appVersion`, `appBundleIdentifier` |
| `Data+CoreExtensions` | Hex string, pretty-printed JSON |
| `Date+CoreExtensions` | `startOfDay`, `addingDays`, `durationString`, ISO 8601 / short formatting |
| `DateRange+CoreExtensions` | `durationString`, `displayString` on `Range<Date>` and `ClosedRange<Date>` |
| `Decimal+CoreExtensions` | Currency and percentage formatting |
| `Double+CoreExtensions` | Rounding, formatting helpers |
| `Int+CoreExtensions` | Byte count formatting |
| `SortOrder+CoreExtensions` | Toggle, comparator helpers |
| `String+CoreExtensions` | `isBlank`, truncation, email validation, masking |

### Utilities

- **`StructCache<T>`** — Actor-based in-memory cache backed by `NSCache`.
- **`Casey`** — Build CSV text and optionally save to the Downloads folder.
- **`Yo`** — Structured user-facing message with summary, details, and kind (`.info`, `.caution`, `.success`, `.warning`).
- **`OAuthToken`** — Codable OAuth 2.0 token with expiration helpers.

## Error Handling

All MirageKit modules throw errors conforming to the `Yikes` protocol, which extends `LocalizedError` with structured fields:

```swift
public protocol MirageKitError: Error, LocalizedError, Sendable {
    var summary: String { get }
    var title: String? { get }
    var details: String? { get }
    var underlyingError: (any Error)? { get }
    var refcode: String? { get }
    var userInfo: [String: any Sendable]? { get }
}
```

Concrete error types: `LabradorError`, `JaysonError`, `EarlError`, `KeeperError`, `CaseyError`.

## License

MIT License. Copyright 2025 Wells Consulting. See [LICENSE](LICENSE) for details.
