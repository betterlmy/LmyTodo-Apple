# LmyTodo Apple客户端

这是一个基于SwiftUI开发的Todo应用，支持用户注册、登录和Todo管理功能。

## 功能特性

- 📱 现代化的SwiftUI界面
- 🔐 JWT认证系统
- ✅ Todo的增删改查
- 🌐 完整的网络请求处理
- 📊 详细的网络请求日志
- ⚙️ 灵活的配置管理系统

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd LmyTodo-Apple
```

### 2. 配置API服务器地址

项目支持多种配置方式来设置API服务器地址：

#### 方法一：使用配置文件（推荐）
1. 复制配置模板：
   ```bash
   cp LmyTodoList/Config.plist.example LmyTodoList/Config.plist
   ```

2. 编辑 `LmyTodoList/Config.plist` 文件，修改API地址：
   ```xml
   <key>API_BASE_URL</key>
   <string>http://your-server.com:8080</string>
   ```

#### 方法二：使用环境变量
在Xcode中设置环境变量：
1. 选择项目 Scheme → Edit Scheme
2. 在 Run → Environment Variables 中添加：
   - Name: `API_BASE_URL`
   - Value: `http://your-server.com:8080`

#### 方法三：修改默认值
如果没有配置文件和环境变量，应用会使用默认地址 `http://localhost:8080`

### 3. 在Xcode中打开项目
```bash
open LmyTodoList.xcodeproj
```

### 4. 运行应用
选择目标设备或模拟器，然后按 `Cmd + R` 运行应用。

## 项目结构

```
LmyTodoList/
├── LmyTodoListApp.swift      # 应用入口
├── Config.swift              # 配置管理器
├── Config.plist              # 配置文件（不会提交到Git）
├── Config.plist.example      # 配置文件模板
├── NetworkManager.swift      # 网络请求管理
├── Models.swift              # 数据模型
├── AuthManager.swift         # 认证管理
├── TodoManager.swift         # Todo管理
├── Views/
│   ├── ContentView.swift     # 主视图
│   ├── LoginView.swift       # 登录视图
│   ├── TodoListView.swift    # Todo列表视图
│   └── AddTodoView.swift     # 添加Todo视图
└── Assets.xcassets/          # 资源文件
```

## 配置说明

### 配置优先级
1. **环境变量** `API_BASE_URL`（最高优先级）
2. **配置文件** `Config.plist`
3. **默认值** `http://localhost:8080`（最低优先级）

### 安全注意事项
- `Config.plist` 文件已加入 `.gitignore`，不会被提交到版本控制
- 请使用 `Config.plist.example` 作为模板
- 生产环境建议使用环境变量配置

## API文档

应用与后端API通信，所有请求都使用POST方法：

- `POST /api/register` - 用户注册
- `POST /api/login` - 用户登录
- `POST /api/profile` - 获取用户信息
- `POST /api/todos/list` - 获取Todo列表
- `POST /api/todos/create` - 创建Todo
- `POST /api/todos/update` - 更新Todo
- `POST /api/todos/delete` - 删除Todo

## 开发说明

### 网络请求日志
应用内置了详细的网络请求日志功能，包括：
- 🚀 请求信息（URL、方法、认证状态、请求体）
- 📥 响应信息（状态码、数据大小、响应内容）
- ❌ 错误信息（详细的错误分类和描述）

### 错误处理
项目实现了完整的错误处理机制：
- 网络连接错误
- HTTP状态码错误
- API业务错误
- 数据解析错误

## 许可证

MIT License