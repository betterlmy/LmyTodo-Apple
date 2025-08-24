# LmyTodo iOS App - AI Coding Instructions

## Architecture Overview

This is a SwiftUI-based iOS todo app following MVVM pattern with reactive programming using Combine framework. The app communicates with a REST API backend for user authentication and todo management.

### Core Components

- **AuthManager**: Observable state manager for user authentication with JWT token persistence
- **TodoManager**: Observable state manager for todo CRUD operations
- **NetworkManager**: Singleton handling all HTTP requests with comprehensive error handling
- **Models**: Codable data structures for API communication
- **Views**: SwiftUI views with declarative UI and state binding

## Key Patterns & Conventions

### State Management

- Use `@StateObject` for manager creation (AuthManager, TodoManager)
- Use `@EnvironmentObject` for dependency injection between views
- All managers inherit `ObservableObject` with `@Published` properties for automatic UI updates
- Store JWT tokens in `UserDefaults` with key "jwt_token"

### Networking Architecture

```swift
// All API calls return AnyPublisher<T, Error> using Combine
NetworkManager.shared.login(username: username, password: password)
    .sink(
        receiveCompletion: { [weak self] completion in
            // Handle errors and loading states
        },
        receiveValue: { [weak self] response in
            // Handle success with automatic UI updates
        }
    )
    .store(in: &cancellables)
```

### Error Handling

- Custom `NetworkError` enum with localized descriptions
- Comprehensive HTTP status code handling (401, 403, 409, 500+)
- Network-level error mapping (timeouts, no connection, etc.)
- CloudFlare protection detection and iOS-specific headers

### Code Organization

- Group related functionality with `// MARK: -` comments
- Use descriptive Go-style comments explaining Swift concepts
- File structure: App → ContentView → Manager classes → Models
- Views handle presentation, Managers handle business logic

## Development Workflow

### Building & Running

- Open `LmyTodoList.xcodeproj` in Xcode
- Select iOS Simulator or physical device
- Build with ⌘+B, Run with ⌘+R
- No external package dependencies (uses built-in Combine)

### Testing API Integration

- Backend runs on `http://192.168.2.11:8080/api`
- Check network connectivity if requests fail
- Monitor Xcode console for detailed HTTP request/response logging
- JWT tokens auto-refresh through AuthManager.loadUserProfile()

### Common Tasks

- **Add new API endpoint**: Extend NetworkManager with new method, update Models if needed
- **Add UI screen**: Create SwiftUI view, inject required managers via `@EnvironmentObject`
- **Debug network issues**: Check console logs for HTTP status codes and error details
- **Update state**: Modify `@Published` properties in managers, UI updates automatically

## Specific Implementation Notes

### Authentication Flow

- Login success stores JWT token and sets `authManager.isLoggedIn = true`
- ContentView conditionally renders LoginView vs TodoListView based on auth state
- Logout clears token and resets all state
- Automatic token validation on app launch via AuthManager.checkLoginStatus()

### Todo Operations

- TodoManager.loadTodos() fetches and populates `@Published var todos: [Todo]`
- Create/Update/Delete operations optimistically update local state
- Failed operations restore previous state and show error messages
- Toggle completion uses updateTodo with partial updates

### SwiftUI Patterns

- Use `Group` with conditional rendering for auth state transitions
- Apply `.transition()` and `.animation()` for smooth state changes
- Leverage `#Preview` macros with sample data for UI development
- Follow declarative UI principles - describe what UI should look like, not how to build it

## Error Prevention

- Always use `[weak self]` in Combine closures to prevent retain cycles
- Store all Publishers in `cancellables` set for proper cleanup
- Use `guard let` and early returns for safe unwrapping
- Implement comprehensive error states in all managers
- Test network error scenarios (offline, server down, invalid responses)
