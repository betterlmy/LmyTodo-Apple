//
//  Models.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import Foundation

// MARK: - 用户相关数据模型

/**
 用户模型
 - Codable: 协议，类似Go的json标签，支持JSON序列化/反序列化
 - Identifiable: 协议，要求有id属性，用于SwiftUI列表识别
 */
struct User: Codable, Identifiable {
    let id: Int           // 用户ID (let表示常量，类似Go的只读字段)
    let username: String  // 用户名
    let email: String     // 邮箱
}

/**
 注册请求模型
 - 用于发送注册API请求
 */
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

/**
 登录请求模型
 */
struct LoginRequest: Codable {
    let username: String
    let password: String
}

/**
 登录响应模型
 - 包含JWT token和用户信息
 */
struct LoginResponse: Codable {
    let token: String    // JWT认证令牌
    let user: User       // 用户信息
}

/**
 通用消息响应模型
 - 用于API返回简单消息
 */
struct MessageResponse: Codable {
    let message: String
}

// MARK: - TODO相关数据模型

/**
 TODO任务模型
 - CodingKeys: 枚举，用于映射JSON字段名和Swift属性名
 - 类似Go的json标签功能
 */
struct Todo: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let description: String
    let completed: Bool
    let createdAt: String
    let updatedAt: String
    
    // 自定义JSON字段映射 (类似Go的 `json:"user_id"`)
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"        // JSON中的user_id映射到Swift的userId
        case title
        case description
        case completed
        case createdAt = "created_at"  // 下划线转驼峰命名
        case updatedAt = "updated_at"
    }
}

/**
 创建TODO请求模型
 */
struct CreateTodoRequest: Codable {
    let title: String
    let description: String
}

/**
 更新TODO请求模型
 - 使用可选类型(Optional)，因为更新时不是所有字段都需要提供
 - String? 表示可能为nil的字符串，类似Go的 *string
 */
struct UpdateTodoRequest: Codable {
    let title: String?       // 可选字段
    let description: String? // 可选字段
    let completed: Bool?     // 可选字段
}
