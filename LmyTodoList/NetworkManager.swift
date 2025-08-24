//
//  NetworkManager.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import Foundation
import Combine  // Swift的响应式编程框架，类似RxJava

/**
 网络管理器类
 - ObservableObject: 协议，使对象可被SwiftUI观察
 - 类似Go中的单例模式，但使用Swift的方式实现
 */
class NetworkManager: ObservableObject {
    // 单例模式 - 全局共享一个实例
    static let shared = NetworkManager()
    
    // 后端API基础URL - 从配置文件读取
    private let baseURL: String
    
    // 私有构造函数，确保只能通过shared访问
    private init() {
        self.baseURL = AppConfig.apiBaseURL
        // 打印配置信息，方便调试
        AppConfig.printConfigInfo()
    }
    
    /**
     通用网络请求方法
     - 泛型函数: <T: Codable> 类似Go的泛型
     - AnyPublisher: Combine框架的发布者，类似Go的channel概念
     - Error: Swift的错误类型
     */
    private func makeRequest<T: Codable>(
        endpoint: String,                    // API端点
        method: HTTPMethod,                  // HTTP方法
        body: Data? = nil,                  // 请求体 (可选参数，默认nil)
        requiresAuth: Bool = false          // 是否需要认证
    ) -> AnyPublisher<T, Error> {           // 返回发布者，发布T类型数据或错误
        
        // 安全创建URL，使用guard语句进行早期返回
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ 网络请求失败: 无效URL - \(baseURL + endpoint)")
            // Fail是Combine的失败发布者，类似Go的返回error
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()  // 类型擦除，统一返回类型
        }
        
        // 创建HTTP请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue  // 枚举的原始值
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // 添加更真实的iOS应用User-Agent，模拟真实iOS设备
        let iosVersion = ProcessInfo.processInfo.operatingSystemVersionString
        request.addValue("LmyTodoApp/1.0 (iOS \(iosVersion); iPhone)", forHTTPHeaderField: "User-Agent")
        
        // 添加更多真实的iOS请求头
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("zh-CN,zh-Hans;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.addValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.addValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.addValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        
        // 添加自定义标识头，方便在CloudFlare中识别
        request.addValue("LmyTodoApp-iOS", forHTTPHeaderField: "X-App-Name")
        request.addValue("1.0", forHTTPHeaderField: "X-App-Version")
        
        // 如果需要认证，添加JWT token
        let hasAuth = requiresAuth && UserDefaults.standard.string(forKey: "jwt_token") != nil
        if requiresAuth, let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 如果有请求体，设置body
        if let body = body {
            request.httpBody = body
        }
        
        // 📡 详细的网络请求日志
        print("🚀 开始网络请求")
        print("📍 URL: \(url.absoluteString)")
        print("🔧 方法: \(method.rawValue)")
        print("🔐 需要认证: \(requiresAuth ? "是" : "否")")
        print("🎫 有认证token: \(hasAuth ? "是" : "否")")
        
        if let body = body {
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 请求体: \(bodyString)")
            } else {
                print("📦 请求体: \(body.count) 字节")
            }
        } else {
            print("📦 请求体: 无")
        }
        
        // 打印主要请求头
        print("📋 请求头:")
        print("   Content-Type: \(request.value(forHTTPHeaderField: "Content-Type") ?? "未设置")")
        if hasAuth {
            print("   Authorization: Bearer [TOKEN]")
        }
        print("   X-App-Name: \(request.value(forHTTPHeaderField: "X-App-Name") ?? "未设置")")
        print("---")
        
        // 执行网络请求并返回发布者
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // 检查HTTP状态码
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ 网络响应错误: 无法获取HTTP响应")
                    throw NetworkError.noData
                }
                
                // 📡 详细的网络响应日志
                print("📥 收到网络响应")
                print("📍 URL: \(httpResponse.url?.absoluteString ?? "未知")")
                print("📊 状态码: \(httpResponse.statusCode)")
                print("📏 数据大小: \(data.count) 字节")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 响应数据: \(responseString)")
                } else {
                    print("📄 响应数据: 无法解析为文本")
                }
                print("---")
                
                // 现在后端总是返回200状态码，真正的错误信息在响应体中
                switch httpResponse.statusCode {
                case 200:
                    // 先尝试解析为错误响应
                    if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        print("⚠️ API业务错误: 代码[\(errorResponse.code)] - \(errorResponse.message)")
                        // 如果成功解析为错误响应，抛出错误
                        throw NetworkError.apiError(code: errorResponse.code, message: errorResponse.message)
                    }
                    print("✅ 请求成功")
                    // 否则当作成功响应处理
                    return data
                case 401:
                    print("🔒 认证失败 (401)")
                    // 解析错误信息
                    if let errorData = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        throw NetworkError.authenticationFailed(errorData.message)
                    } else {
                        throw NetworkError.unauthorized
                    }
                case 400:
                    // 请求错误
                    if let errorData = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        throw NetworkError.badRequest(errorData.message)
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 403:
                    // 禁止访问 - 可能被CloudFlare拦截
                    throw NetworkError.forbidden("访问被拒绝，可能被防护系统拦截")
                case 409:
                    // 冲突错误（如用户名已存在）
                    if let errorData = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        throw NetworkError.conflict(errorData.message)
                    } else {
                        throw NetworkError.conflict("数据冲突")
                    }
                case 500...599:
                    // 服务器错误
                    throw NetworkError.serverError("服务器内部错误")
                default:
                    // 其他错误
                    if let errorData = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorData.message)
                    } else {
                        throw NetworkError.unknown("未知错误 (状态码: \(httpResponse.statusCode))")
                    }
                }
            }
            .mapError { error -> Error in
                // 处理网络层面的错误
                print("🔍 网络错误详情: \(error)")
                print("🔍 错误类型: \(type(of: error))")
                
                if let urlError = error as? URLError {
                    print("🔍 URLError 代码: \(urlError.code.rawValue)")
                    print("🔍 URLError 描述: \(urlError.localizedDescription)")
                    
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return NetworkError.connectionFailed("无网络连接")
                    case .timedOut:
                        return NetworkError.connectionFailed("连接超时")
                    case .cannotConnectToHost:
                        return NetworkError.connectionFailed("无法连接到服务器，请检查网络设置")
                    case .networkConnectionLost:
                        return NetworkError.connectionFailed("网络连接中断")
                    case .cannotFindHost:
                        return NetworkError.connectionFailed("找不到服务器")
                    case .secureConnectionFailed:
                        return NetworkError.connectionFailed("安全连接失败")
                    default:
                        return NetworkError.connectionFailed("网络连接失败: \(urlError.localizedDescription)")
                    }
                }
                return error
            }
            .tryMap { (data: Data) in
                // 尝试解析为包装的成功响应
                if let successResponse = try? JSONDecoder().decode(ApiSuccessResponse<T>.self, from: data) {
                    return successResponse.data
                }
                // 如果不是包装响应，直接解析为目标类型
                return try JSONDecoder().decode(T.self, from: data)
            }
            .receive(on: DispatchQueue.main)  // 在主线程接收结果 (UI更新必须在主线程)
            .eraseToAnyPublisher()          // 类型擦除
    }
    
    // MARK: - 认证相关API
    
    /**
     用户注册
     - 参数使用外部参数名，提高可读性
     - 返回AnyPublisher，异步处理结果
     */
    func register(username: String, email: String, password: String) -> AnyPublisher<SimpleSuccessResponse, Error> {
        // 创建请求体
        let body = RegisterRequest(username: username, email: email, password: password)
        
        // 尝试编码为JSON，使用guard进行错误处理
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        // 调用通用请求方法 - 使用更新的API路径
        return makeRequest(endpoint: "/api/register", method: .POST, body: bodyData)
    }
    
    /**
     用户登录
     */
    func login(username: String, password: String) -> AnyPublisher<LoginData, Error> {
        let body = LoginRequest(username: username, password: password)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        // 使用更新的API路径
        return makeRequest(endpoint: "/api/login", method: .POST, body: bodyData)
    }
    
    // MARK: - TODO相关API
    
    /**
     获取TODO列表
     - 需要认证
     - 根据最新swagger文档，现在是POST请求到 /api/todos/list
     */
    func getTodos() -> AnyPublisher<[Todo], Error> {
        // 发送空的JSON对象作为请求体
        let emptyBody = "{}".data(using: .utf8)
        return makeRequest(endpoint: "/api/todos/list", method: .POST, body: emptyBody, requiresAuth: true)
    }
    
    /**
     创建TODO
     - 使用 /api/todos/create 路径
     */
    func createTodo(title: String, description: String) -> AnyPublisher<Todo, Error> {
        let body = CreateTodoRequest(title: title, description: description)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/api/todos/create", method: .POST, body: bodyData, requiresAuth: true)
    }
    
    /**
     更新TODO
     - 使用可选参数，只更新提供的字段
     - 根据swagger文档使用POST方法到 /api/todos/update
     */
    func updateTodo(id: Int, title: String?, description: String?, completed: Bool?) -> AnyPublisher<SimpleSuccessResponse, Error> {
        let body = UpdateTodoRequestWithId(id: id, title: title, description: description, completed: completed)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/api/todos/update", method: .POST, body: bodyData, requiresAuth: true)
    }
    
    /**
     删除TODO
     - 根据swagger文档使用POST方法到 /api/todos/delete
     */
    func deleteTodo(id: Int) -> AnyPublisher<SimpleSuccessResponse, Error> {
        let body = DeleteTodoRequest(id: id)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/api/todos/delete", method: .POST, body: bodyData, requiresAuth: true)
    }
    
    /**
     获取用户信息
     - 根据swagger文档，现在是POST请求到 /api/profile
     */
    func getProfile() -> AnyPublisher<User, Error> {
        // 发送空的JSON对象作为请求体
        let emptyBody = "{}".data(using: .utf8)
        return makeRequest(endpoint: "/api/profile", method: .POST, body: emptyBody, requiresAuth: true)
    }
}

/**
 HTTP方法枚举
 - String: 原始值类型，枚举值对应字符串
 - 类似Go的常量定义，但更类型安全
 */
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

/**
 网络错误枚举
 - Error: 协议，使枚举可以作为错误抛出
 - LocalizedError: 协议，提供本地化错误描述
 */
enum NetworkError: Error, LocalizedError {
    case invalidURL                    // 无效URL
    case encodingError                // 编码错误
    case noData                       // 无数据
    case unauthorized                 // 未授权（通用）
    case authenticationFailed(String) // 认证失败（带详细信息）
    case badRequest(String)           // 请求错误（带详细信息）
    case forbidden(String)            // 禁止访问（403错误）
    case conflict(String)             // 冲突错误（如用户名已存在）
    case serverError(String)          // 服务器错误
    case connectionFailed(String)     // 连接失败（网络层面的错误）
    case apiError(code: Int, message: String)  // API业务错误（后端返回的错误）
    case unknown(String)              // 未知错误（带详细信息）
    
    // 实现 LocalizedError 协议的必需属性
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .encodingError:
            return "数据编码错误"
        case .noData:
            return "没有数据"
        case .unauthorized:
            return "未授权访问"
        case .authenticationFailed(let message):
            return "登录失败: \(message)"
        case .badRequest(let message):
            return "请求错误: \(message)"
        case .forbidden(let message):
            return "访问被拒绝: \(message)"
        case .conflict(let message):
            return "冲突: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .connectionFailed(let message):
            return "连接失败: \(message)"
        case .apiError(let code, let message):
            return "API错误(\(code)): \(message)"
        case .unknown(let message):
            return "错误: \(message)"
        }
    }
    
    // 可选：失败原因
    var failureReason: String? {
        switch self {
        case .apiError(let code, let message):
            return "后端API返回错误代码 \(code)：\(message)"
        case .connectionFailed(let message):
            return "网络连接问题：\(message)"
        default:
            return nil
        }
    }
    
    // 可选：恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "请检查用户名和密码是否正确"
        case .connectionFailed:
            return "请检查网络连接或稍后重试"
        case .apiError(let code, _):
            switch code {
            case 10003:
                return "请检查账号密码是否正确"
            case 10002:
                return "该用户名已被注册，请选择其他用户名"
            default:
                return "请稍后重试或联系技术支持"
            }
        default:
            return nil
        }
    }
    
    // 计算属性，提供错误描述 (保持向后兼容)
    var localizedDescription: String {
        return errorDescription ?? "未知错误"
    }
}

/**
 后端错误响应模型
 - 用于解析后端返回的错误信息
 */
struct ErrorResponse: Codable {
    let error: String
}
