//
//  Config.swift
//  LmyTodoList
//
//  Created by Zane on 2025/8/24.
//

import Foundation

/**
 应用配置管理器
 - 负责管理应用的配置信息，如服务器地址等
 - 支持从多个来源读取配置：环境变量、配置文件、默认值
 */
struct AppConfig {
    
    /**
     获取API服务器基础URL
     优先级顺序：
     1. 环境变量 API_BASE_URL
     2. Config.plist 文件中的配置
     3. 默认的本地开发地址
     */
    static var apiBaseURL: String {
        // 1. 首先尝试从环境变量读取（适用于CI/CD部署）
        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"] {
            return envURL
        }
        
        // 2. 尝试从Config.plist文件读取
        if let configURL = getConfigFromPlist() {
            return configURL
        }
        
        // 3. 返回默认的开发环境地址
        return "http://localhost:8080"
    }
    
    /**
     从Config.plist文件读取配置
     */
    private static func getConfigFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let baseURL = plist["API_BASE_URL"] as? String else {
            print("📋 未找到Config.plist文件或API_BASE_URL配置")
            return nil
        }
        
        print("📋 从Config.plist读取API地址: \(baseURL)")
        return baseURL
    }
    
    /**
     检查当前配置来源并打印信息
     */
    static func printConfigInfo() {
        let url = apiBaseURL
        print("🔧 当前API配置:")
        print("📍 URL: \(url)")
        
        if ProcessInfo.processInfo.environment["API_BASE_URL"] != nil {
            print("📋 配置来源: 环境变量")
        } else if getConfigFromPlist() != nil {
            print("📋 配置来源: Config.plist文件")
        } else {
            print("📋 配置来源: 默认值 (开发环境)")
        }
        print("---")
    }
}
