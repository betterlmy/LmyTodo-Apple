//
//  AuthManager.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import Foundation
import Combine

/**
 认证管理器
 - ObservableObject: 可观察对象协议，当属性变化时通知UI更新
 - 类似Go中的状态管理，但集成了响应式编程
 */
class AuthManager: ObservableObject {
    // MARK: - 发布属性
    
    /**
     @Published: 属性包装器，当值改变时自动通知订阅者
     - 类似Go中的channel广播，但更自动化
     - SwiftUI会监听这些属性的变化并自动重新渲染UI
     */
    @Published var isLoggedIn = false        // 登录状态
    @Published var currentUser: User?        // 当前用户信息 (可选类型)
    @Published var errorMessage: String?     // 错误信息 (可选类型)
    @Published var registerSuccessMessage: String? // 注册成功消息
    @Published var isLoading = false         // 加载状态
    
    // MARK: - 私有属性
    
    /**
     Combine框架的订阅集合
     - Set<AnyCancellable>: 存储所有网络请求的订阅
     - 类似Go的context取消机制，防止内存泄漏
     */
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /**
     初始化方法
     - Swift中的构造函数，类似Go的构造函数
     */
    init() {
        checkLoginStatus()  // 检查本地登录状态
    }
    
    // MARK: - 私有方法
    
    /**
     检查本地登录状态
     - 从UserDefaults读取JWT token
     - UserDefaults类似本地存储，用于持久化简单数据
     */
    private func checkLoginStatus() {
        // 从本地存储获取JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token"), !token.isEmpty {
            isLoggedIn = true
            loadUserProfile()  // 加载用户信息
        }else{
            isLoggedIn = false  // 没有token，未登录
            currentUser = nil   // 清除当前用户信息
        }
    }
    
    /**
     加载用户资料
     - 验证token是否有效
     - 如果token过期，自动退出登录
     */
    private func loadUserProfile() {
        NetworkManager.shared.getProfile()
            .sink(
                receiveCompletion: { [weak self] completion in
                    /**
                     [weak self]: 弱引用，防止循环引用
                     - 类似Go中的指针，但更安全
                     - 避免内存泄漏
                     */
                    if case .failure(_) = completion {
                        // Token可能已过期，需要重新登录
                        self?.logout()
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)  // 存储订阅，管理生命周期
    }
    
    // MARK: - 公共方法
    
    /**
     用户注册
     - 使用Combine进行异步网络请求
     - sink: 订阅发布者，处理结果和错误
     - 注册成功后设置成功消息
     - 改进错误处理，提供详细的错误信息
     */
    func register(username: String, email: String, password: String) {
        isLoading = true  // 开始加载
        print("开始注册用户: \(username), 邮箱: \(email)") // 调试日志
        
        NetworkManager.shared.register(username: username, email: email, password: password)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false  // 结束加载
                    
                    switch completion {
                    case .finished:
                        print("注册请求完成") // 调试日志
                    case .failure(let error):
                        print("注册失败: \(error.localizedDescription)") // 调试日志
                        // 如果失败，设置错误信息
                        self?.errorMessage = error.localizedDescription
                        self?.registerSuccessMessage = nil
                    }
                },
                receiveValue: { [weak self] response in
                    print("注册成功响应: \(response)") // 调试日志
                    // 注册成功，设置成功消息并清除错误信息
                    self?.registerSuccessMessage = "注册成功！请使用您的账号登录。"
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)  // 存储订阅
    }
    
    /**
     用户登录
     - 成功后保存token和用户信息
     - 改进错误处理，提供详细的错误信息
     */
    func login(username: String, password: String) {
        isLoading = true  // 开始加载
        print("开始登录用户: \(username)") // 调试日志

        NetworkManager.shared.login(username: username, password: password) // 发起登录请求
            .sink( // sink是 Combine 的订阅方法
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false  // 结束加载
                    
                    switch completion {
                    case .finished:
                        print("登录请求完成") // 调试日志
                    case .failure(let error):
                        print("❌ 登录失败详情: \(error)")
                        print("❌ 错误类型: \(type(of: error))")
                        print("❌ 错误描述: \(error.localizedDescription)")
                        
                        // 检查是否是网络错误
                        if let networkError = error as? NetworkError {
                            print("❌ 网络错误枚举: \(networkError)")
                            print("❌ 网络错误localizedDescription: \(networkError.localizedDescription)")
                            print("❌ 网络错误errorDescription: \(networkError.errorDescription ?? "nil")")
                        }
                        
                        // 优先使用 errorDescription (LocalizedError 协议)
                        let errorMsg: String
                        if let localizedError = error as? LocalizedError,
                           let errorDescription = localizedError.errorDescription {
                            errorMsg = errorDescription
                            print("✅ 使用 LocalizedError.errorDescription: '\(errorMsg)'")
                        } else {
                            errorMsg = error.localizedDescription
                            print("⚠️ 使用标准 localizedDescription: '\(errorMsg)'")
                        }
                        
                        print("❌ 即将设置给UI的错误信息: '\(errorMsg)'")
                        self?.errorMessage = errorMsg
                        self?.isLoggedIn = false // 确保登录状态为false
                    }
                },
                receiveValue: { [weak self] loginData in
                    print("登录成功，用户: \(loginData.user.username)") // 调试日志
                    // 登录成功处理
                    UserDefaults.standard.set(loginData.token, forKey: "jwt_token")  // 保存token
                    self?.currentUser = loginData.user     // 设置当前用户
                    self?.isLoggedIn = true              // 更新登录状态
                    self?.errorMessage = nil             // 清除错误信息
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     用户退出登录
     - 清除本地数据和状态
     */
    func logout() {
        UserDefaults.standard.removeObject(forKey: "jwt_token")  // 删除token
        currentUser = nil        // 清除用户信息
        isLoggedIn = false      // 更新登录状态
    }
    
    /**
     清除注册成功消息
     */
    func clearRegisterSuccessMessage() {
        registerSuccessMessage = nil
    }
}
