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
    
    // 后端API基础URL
    private let baseURL = "http://117.72.159.104:8080/api"
    
    // 私有构造函数，确保只能通过shared访问
    private init() {}
    
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
            // Fail是Combine的失败发布者，类似Go的返回error
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()  // 类型擦除，统一返回类型
        }
        
        // 创建HTTP请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue  // 枚举的原始值
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 如果需要认证，添加JWT token
        if requiresAuth, let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 如果有请求体，设置body
        if let body = body {
            request.httpBody = body
        }
        
        // 执行网络请求并返回发布者
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // 检查HTTP状态码
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.noData
                }
                
                // 处理不同的HTTP状态码
                switch httpResponse.statusCode {
                case 200...299:
                    // 成功状态码，返回数据
                    return data
                case 401:
                    // 解析错误信息
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.authenticationFailed(errorData.error)
                    } else {
                        throw NetworkError.unauthorized
                    }
                case 400:
                    // 请求错误
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.badRequest(errorData.error)
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 409:
                    // 冲突错误（如用户名已存在）
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.conflict(errorData.error)
                    } else {
                        throw NetworkError.conflict("数据冲突")
                    }
                case 500...599:
                    // 服务器错误
                    throw NetworkError.serverError("服务器内部错误")
                default:
                    // 其他错误
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorData.error)
                    } else {
                        throw NetworkError.unknown("未知错误 (状态码: \(httpResponse.statusCode))")
                    }
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())  // JSON解码
            .receive(on: DispatchQueue.main)  // 在主线程接收结果 (UI更新必须在主线程)
            .eraseToAnyPublisher()          // 类型擦除
    }
    
    // MARK: - 认证相关API
    
    /**
     用户注册
     - 参数使用外部参数名，提高可读性
     - 返回AnyPublisher，异步处理结果
     */
    func register(username: String, email: String, password: String) -> AnyPublisher<MessageResponse, Error> {
        // 创建请求体
        let body = RegisterRequest(username: username, email: email, password: password)
        
        // 尝试编码为JSON，使用guard进行错误处理
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        // 调用通用请求方法
        return makeRequest(endpoint: "/register", method: .POST, body: bodyData)
    }
    
    /**
     用户登录
     */
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, Error> {
        let body = LoginRequest(username: username, password: password)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/login", method: .POST, body: bodyData)
    }
    
    // MARK: - TODO相关API
    
    /**
     获取TODO列表
     - 需要认证
     */
    func getTodos() -> AnyPublisher<[Todo], Error> {
        return makeRequest(endpoint: "/todos", method: .GET, requiresAuth: true)
    }
    
    /**
     创建TODO
     */
    func createTodo(title: String, description: String) -> AnyPublisher<Todo, Error> {
        let body = CreateTodoRequest(title: title, description: description)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/todos", method: .POST, body: bodyData, requiresAuth: true)
    }
    
    /**
     更新TODO
     - 使用可选参数，只更新提供的字段
     */
    func updateTodo(id: Int, title: String?, description: String?, completed: Bool?) -> AnyPublisher<MessageResponse, Error> {
        let body = UpdateTodoRequest(title: title, description: description, completed: completed)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(endpoint: "/todos/\(id)", method: .PUT, body: bodyData, requiresAuth: true)
    }
    
    /**
     删除TODO
     */
    func deleteTodo(id: Int) -> AnyPublisher<MessageResponse, Error> {
        return makeRequest(endpoint: "/todos/\(id)", method: .DELETE, requiresAuth: true)
    }
    
    /**
     获取用户信息
     */
    func getProfile() -> AnyPublisher<User, Error> {
        return makeRequest(endpoint: "/profile", method: .GET, requiresAuth: true)
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
 - 实现localizedDescription提供错误描述
 */
enum NetworkError: Error {
    case invalidURL                    // 无效URL
    case encodingError                // 编码错误
    case noData                       // 无数据
    case unauthorized                 // 未授权（通用）
    case authenticationFailed(String) // 认证失败（带详细信息）
    case badRequest(String)           // 请求错误（带详细信息）
    case conflict(String)             // 冲突错误（如用户名已存在）
    case serverError(String)          // 服务器错误
    case unknown(String)              // 未知错误（带详细信息）
    
    // 计算属性，提供错误描述
    var localizedDescription: String {
        switch self {  // switch必须覆盖所有情况
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
        case .conflict(let message):
            return "冲突: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .unknown(let message):
            return "错误: \(message)"
        }
    }
}

/**
 后端错误响应模型
 - 用于解析后端返回的错误信息
 */
struct ErrorResponse: Codable {
    let error: String
}
