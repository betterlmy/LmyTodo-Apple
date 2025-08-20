# Go开发者的Swift快速对照表

## 基础语法对比

| 概念          | Go                         | Swift                       |
| ------------- | -------------------------- | --------------------------- |
| **变量声明**  | `var name string = "John"` | `var name: String = "John"` |
| **常量声明**  | `const pi = 3.14`          | `let pi = 3.14`             |
| **类型推断**  | `name := "John"`           | `let name = "John"`         |
| **可空值**    | `var ptr *string`          | `var name: String?`         |
| **数组**      | `[]int{1, 2, 3}`           | `[Int]([1, 2, 3])`          |
| **字典/映射** | `map[string]int`           | `[String: Int]`             |
| **结构体**    | `type User struct{}`       | `struct User {}`            |

## 函数定义

### Go
```go
func add(a, b int) int {
    return a + b
}

func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
```

### Swift
```swift
func add(a: Int, b: Int) -> Int {
    return a + b
}

func divide(a: Double, b: Double) throws -> Double {
    guard b != 0 else {
        throw DivisionError.divisionByZero
    }
    return a / b
}
```

## 错误处理

### Go
```go
result, err := divide(10, 0)
if err != nil {
    log.Printf("错误: %v", err)
    return
}
fmt.Printf("结果: %f", result)
```

### Swift
```swift
do {
    let result = try divide(a: 10, b: 0)
    print("结果: \(result)")
} catch {
    print("错误: \(error)")
}
```

## 接口/协议

### Go
```go
type Writer interface {
    Write([]byte) (int, error)
}

type FileWriter struct{}

func (f FileWriter) Write(data []byte) (int, error) {
    // 实现写入逻辑
    return len(data), nil
}
```

### Swift
```swift
protocol Writer {
    func write(data: Data) throws -> Int
}

struct FileWriter: Writer {
    func write(data: Data) throws -> Int {
        // 实现写入逻辑
        return data.count
    }
}
```

## 并发处理

### Go - Goroutines
```go
func fetchData(url string, ch chan<- string) {
    // 模拟网络请求
    time.Sleep(time.Second)
    ch <- "数据来自: " + url
}

func main() {
    ch := make(chan string, 2)
    
    go fetchData("api1.com", ch)
    go fetchData("api2.com", ch)
    
    for i := 0; i < 2; i++ {
        result := <-ch
        fmt.Println(result)
    }
}
```

### Swift - Async/Await
```swift
func fetchData(from url: String) async -> String {
    // 模拟网络请求
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    return "数据来自: \(url)"
}

func main() async {
    async let result1 = fetchData(from: "api1.com")
    async let result2 = fetchData(from: "api2.com")
    
    let results = await [result1, result2]
    for result in results {
        print(result)
    }
}
```

## JSON处理

### Go
```go
type User struct {
    ID       int    `json:"id"`
    Username string `json:"username"`
}

// 序列化
user := User{ID: 1, Username: "john"}
jsonData, err := json.Marshal(user)

// 反序列化
var user User
err := json.Unmarshal(jsonData, &user)
```

### Swift
```swift
struct User: Codable {
    let id: Int
    let username: String
}

// 序列化
let user = User(id: 1, username: "john")
let jsonData = try JSONEncoder().encode(user)

// 反序列化
let user = try JSONDecoder().decode(User.self, from: jsonData)
```

## 内存管理

### Go
```go
// 垃圾回收器自动管理内存
func createUser() *User {
    user := &User{Name: "John"}
    return user  // 可以安全返回局部变量地址
}
```

### Swift
```swift
// ARC (自动引用计数) 管理内存
class User {
    let name: String
    init(name: String) { self.name = name }
}

// 避免循环引用
class Parent {
    var children: [Child] = []
}

class Child {
    weak var parent: Parent?  // weak 避免循环引用
}
```

## 字符串处理

### Go
```go
name := "John"
age := 25
message := fmt.Sprintf("你好, %s! 你%d岁了。", name, age)

// 字符串包含检查
if strings.Contains(message, "John") {
    fmt.Println("包含John")
}
```

### Swift
```swift
let name = "John"
let age = 25
let message = "你好, \(name)! 你\(age)岁了。"  // 字符串插值

// 字符串包含检查
if message.contains("John") {
    print("包含John")
}
```

## 集合操作

### Go
```go
// 切片操作
numbers := []int{1, 2, 3, 4, 5}

// 过滤
var evens []int
for _, n := range numbers {
    if n%2 == 0 {
        evens = append(evens, n)
    }
}

// 映射
var doubled []int
for _, n := range numbers {
    doubled = append(doubled, n*2)
}
```

### Swift
```swift
let numbers = [1, 2, 3, 4, 5]

// 过滤
let evens = numbers.filter { $0 % 2 == 0 }

// 映射
let doubled = numbers.map { $0 * 2 }

// 链式操作
let result = numbers
    .filter { $0 % 2 == 0 }
    .map { $0 * 2 }
    .reduce(0, +)
```

## 包/模块系统

### Go
```go
// go.mod
module myapp

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
)

// 导入
import (
    "fmt"
    "github.com/gin-gonic/gin"
)
```

### Swift
```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0")
    ]
)

// 导入
import Foundation
import Alamofire
```

## 测试

### Go
```go
func TestAdd(t *testing.T) {
    result := add(2, 3)
    expected := 5
    if result != expected {
        t.Errorf("add(2, 3) = %d; want %d", result, expected)
    }
}
```

### Swift
```swift
import XCTest

class MathTests: XCTestCase {
    func testAdd() {
        let result = add(a: 2, b: 3)
        let expected = 5
        XCTAssertEqual(result, expected, "add(2, 3) should equal 5")
    }
}
```

## 关键差异总结

| 特性           | Go                    | Swift                 |
| -------------- | --------------------- | --------------------- |
| **类型系统**   | 显式类型 + 类型推断   | 强类型推断            |
| **内存管理**   | 垃圾回收              | ARC (自动引用计数)    |
| **并发模型**   | Goroutines + Channels | async/await + Actors  |
| **错误处理**   | 返回 error            | throws/try/catch      |
| **空值安全**   | 指针可能为 nil        | Optional 类型强制检查 |
| **面向对象**   | 组合优于继承          | 协议 + 类/结构体      |
| **编译速度**   | 非常快                | 相对较慢              |
| **运行时性能** | 高性能                | 高性能                |
| **生态系统**   | 服务器端、云原生      | 苹果生态系统          |

通过这个对照表，你可以快速理解Swift和Go的相似点和差异，帮助你更快上手Swift开发！
