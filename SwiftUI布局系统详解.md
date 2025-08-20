# SwiftUI布局系统详解

## 1. 基本布局容器

### VStack - 垂直堆栈
```swift
VStack(spacing: 20) {        // spacing: 子视图间距
    Text("第一行")
    Text("第二行")
    Text("第三行")
}
```

### HStack - 水平堆栈
```swift
HStack(spacing: 10) {
    Image(systemName: "star")
    Text("评分")
    Spacer()                 // 占位符，推动其他视图
    Text("5.0")
}
```

### ZStack - 层叠堆栈
```swift
ZStack {
    Color.blue               // 背景层
    Text("前景文本")          // 前景层
}
```

## 2. 修饰符 (Modifiers)

SwiftUI使用链式调用的修饰符模式：

```swift
Text("Hello")
    .font(.title)           // 字体
    .foregroundColor(.red)  // 文字颜色
    .padding()              // 内边距
    .background(Color.yellow) // 背景色
    .cornerRadius(8)        // 圆角
```

### 常用修饰符

#### 尺寸和布局
```swift
.frame(width: 100, height: 50)    // 固定尺寸
.frame(maxWidth: .infinity)        // 最大宽度
.padding()                         // 默认内边距
.padding(.horizontal, 16)          // 水平内边距
.offset(x: 10, y: 20)             // 位置偏移
```

#### 外观
```swift
.background(Color.blue)            // 背景色
.foregroundColor(.white)           // 前景色
.font(.title)                      // 字体
.cornerRadius(10)                  // 圆角
.shadow(radius: 5)                 // 阴影
```

#### 交互
```swift
.onTapGesture {                    // 点击手势
    print("被点击了")
}
.disabled(true)                    // 禁用
.opacity(0.5)                      // 透明度
```

## 3. 数据绑定

### @State - 本地状态
```swift
struct ContentView: View {
    @State private var count = 0   // 本地状态
    
    var body: some View {
        VStack {
            Text("计数: \(count)")
            Button("增加") {
                count += 1         // 修改状态会自动更新UI
            }
        }
    }
}
```

### 双向绑定 ($)
```swift
@State private var text = ""

TextField("输入文本", text: $text)  // $text创建双向绑定
```

### @ObservedObject - 观察外部对象
```swift
class DataModel: ObservableObject {
    @Published var items: [String] = []  // 发布属性变化
}

struct ContentView: View {
    @ObservedObject var dataModel = DataModel()
    
    var body: some View {
        List(dataModel.items, id: \.self) { item in
            Text(item)
        }
    }
}
```

## 4. 列表和导航

### List - 列表视图
```swift
List(todos) { todo in              // todos是Identifiable数组
    HStack {
        Text(todo.title)
        Spacer()
        if todo.completed {
            Image(systemName: "checkmark")
        }
    }
}
```

### NavigationView - 导航
```swift
NavigationView {
    List {
        NavigationLink("详情", destination: DetailView())
    }
    .navigationTitle("标题")
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("添加") { }
        }
    }
}
```

## 5. 表单和输入

### Form - 表单容器
```swift
Form {
    Section(header: Text("个人信息")) {
        TextField("姓名", text: $name)
        TextField("邮箱", text: $email)
    }
    
    Section(header: Text("设置")) {
        Toggle("推送通知", isOn: $notifications)
        Picker("主题", selection: $theme) {
            Text("浅色").tag("light")
            Text("深色").tag("dark")
        }
    }
}
```

## 6. 条件渲染和循环

### 条件渲染
```swift
VStack {
    if isLoggedIn {
        Text("欢迎回来!")
    } else {
        Button("登录") { }
    }
}
```

### 循环渲染
```swift
VStack {
    ForEach(items) { item in
        Text(item.name)
    }
}
```

## 7. 生命周期

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .onAppear {            // 视图出现时
                print("视图已显示")
            }
            .onDisappear {         // 视图消失时
                print("视图已隐藏")
            }
    }
}
```

## 8. 环境变量

```swift
struct ContentView: View {
    @Environment(\.dismiss) var dismiss        // 关闭视图
    @Environment(\.colorScheme) var colorScheme // 颜色主题
    
    var body: some View {
        VStack {
            Text("当前主题: \(colorScheme == .dark ? "深色" : "浅色")")
            Button("关闭") {
                dismiss()
            }
        }
    }
}
```

## 9. 自定义视图

```swift
struct CustomButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
}

// 使用
CustomButton(title: "点击我") {
    print("按钮被点击")
}
```

## 10. 动画

```swift
struct AnimatedView: View {
    @State private var isRotated = false
    
    var body: some View {
        Rectangle()
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(isRotated ? 45 : 0))
            .animation(.easeInOut(duration: 1), value: isRotated)
            .onTapGesture {
                isRotated.toggle()
            }
    }
}
```

这些概念组合起来就能构建出复杂的用户界面！SwiftUI的声明式特性让UI开发变得更加直观和高效。
