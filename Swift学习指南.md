# Swift语言学习指南 - 基于TODO应用代码

作为一个Go开发者，你会发现Swift在很多概念上都有相似之处。让我通过我们的TODO应用代码来介绍Swift的核心概念。

## 1. 基础语法对比

### Go vs Swift 基础语法
```go
// Go
type User struct {
    ID       int    `json:"id"`
    Username string `json:"username"`
}

func getUserInfo() User {
    return User{ID: 1, Username: "test"}
}
```

```swift
// Swift
struct User: Codable {
    let id: Int
    let username: String
}

func getUserInfo() -> User {
    return User(id: 1, username: "test")
}
```

## 2. 变量声明

### Swift的变量声明
```swift
// 常量 (类似Go的const，但更强大)
let name = "张三"           // 自动推断类型为String
let age: Int = 25          // 显式声明类型

// 变量 (类似Go的var)
var count = 0              // 可变变量
var username: String?      // 可选类型(Optional) - 类似Go的指针概念
```

### Go对比
```go
// Go
const name = "张三"
const age int = 25

var count = 0
var username *string  // 指针，可能为nil
```

## 3. 可选类型 (Optional) - Swift的杀手级特性

这是Swift独有的概念，用来安全处理可能为空的值：

```swift
// 可选类型声明
var email: String?        // 可能为nil
var userId: Int?          // 可能为nil

// 安全解包
if let userEmail = email {
    print("邮箱是: \(userEmail)")  // 只有email不为nil时才执行
}

// 空合并操作符
let displayName = username ?? "匿名用户"  // 如果username为nil，使用"匿名用户"
```

## 4. 结构体和类

### Swift中的struct vs class
```swift
// Struct (值类型，类似Go的struct)
struct User: Codable {
    let id: Int
    let username: String
    
    // 计算属性
    var displayName: String {
        return "@\(username)"
    }
}

// Class (引用类型，类似Go的指针)
class UserManager: ObservableObject {
    @Published var currentUser: User?  // 发布者属性，UI会自动更新
    
    func login(user: User) {
        self.currentUser = user
    }
}
```

## 5. 协议 (Protocol) - 类似Go的interface

```swift
// 定义协议
protocol NetworkServiceProtocol {
    func fetchData() -> Data
}

// 实现协议
class APIService: NetworkServiceProtocol {
    func fetchData() -> Data {
        // 实现逻辑
        return Data()
    }
}
```

## 6. 泛型 - 类似Go的泛型

```swift
// 泛型函数
func makeRequest<T: Codable>(endpoint: String) -> T? {
    // 网络请求逻辑
    return nil
}

// 使用
let user: User? = makeRequest(endpoint: "/api/profile")
```

## 7. 闭包 - 类似Go的函数字面量

```swift
// 闭包定义
let completion: (Result<User, Error>) -> Void = { result in
    switch result {
    case .success(let user):
        print("用户: \(user.username)")
    case .failure(let error):
        print("错误: \(error)")
    }
}

// 简化写法
users.map { $0.username }  // 类似Go的匿名函数
```

## 8. SwiftUI - 声明式UI框架

SwiftUI使用声明式语法，类似React：

```swift
struct ContentView: View {
    @State private var username = ""    // 状态变量
    @ObservedObject var userManager: UserManager
    
    var body: some View {  // 计算属性，返回UI
        VStack {  // 垂直堆栈
            TextField("用户名", text: $username)  // $表示双向绑定
            
            Button("登录") {
                // 按钮点击事件
                userManager.login(username: username)
            }
        }
    }
}
```

## 9. 属性包装器 (Property Wrappers)

这是Swift的强大特性，用于添加额外行为：

```swift
@State private var isLoading = false        // 状态管理
@ObservedObject var authManager: AuthManager // 监听对象变化
@Published var todos: [Todo] = []           // 发布变化通知
@Environment(\.dismiss) var dismiss         // 环境变量
```

## 10. 错误处理

### Swift vs Go 错误处理
```swift
// Swift - 使用枚举定义错误
enum NetworkError: Error {
    case invalidURL
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "无效URL"
        case .noData: return "无数据"
        }
    }
}

// 抛出错误
func fetchData() throws -> Data {
    guard let url = URL(string: "https://api.com") else {
        throw NetworkError.invalidURL
    }
    // ...
}

// 处理错误
do {
    let data = try fetchData()
} catch {
    print("错误: \(error)")
}
```

```go
// Go - 返回error
type NetworkError struct {
    Message string
}

func (e NetworkError) Error() string {
    return e.Message
}

func fetchData() ([]byte, error) {
    if someCondition {
        return nil, NetworkError{Message: "无效URL"}
    }
    // ...
    return data, nil
}

// 处理错误
data, err := fetchData()
if err != nil {
    fmt.Printf("错误: %v", err)
}
```

## 11. 响应式编程 - Combine框架

Combine是Swift的响应式编程框架，类似RxJava：

```swift
// 创建发布者
let publisher = URLSession.shared.dataTaskPublisher(for: url)

// 链式操作
publisher
    .map(\.data)                    // 提取数据
    .decode(type: User.self, decoder: JSONDecoder())  // 解码
    .receive(on: DispatchQueue.main)  // 切换到主线程
    .sink(
        receiveCompletion: { completion in
            // 处理完成
        },
        receiveValue: { user in
            // 处理结果
            print("用户: \(user.username)")
        }
    )
    .store(in: &cancellables)  // 存储订阅
```

## 12. 关键差异总结

| 特性         | Go                  | Swift                          |
| ------------ | ------------------- | ------------------------------ |
| **内存管理** | 垃圾回收            | ARC (自动引用计数)             |
| **空值安全** | 指针可能为nil       | Optional类型强制检查           |
| **错误处理** | 返回error           | throws/try/catch 或 Result类型 |
| **并发**     | goroutine + channel | async/await + Combine          |
| **类型系统** | 静态类型            | 静态类型 + 类型推断            |
| **面向对象** | 组合 > 继承         | 协议 + 类/结构体               |
| **UI开发**   | 第三方框架          | SwiftUI (原生)                 |

## 13. 最佳实践

1. **优先使用struct而不是class** (类似Go的组合)
2. **善用可选类型避免空指针异常**
3. **使用guard语句进行早期返回**
4. **利用属性包装器简化代码**
5. **遵循单一职责原则**

通过这个TODO应用的代码，你可以看到Swift如何将类型安全、响应式编程和声明式UI结合在一起，创造出现代化的开发体验！
