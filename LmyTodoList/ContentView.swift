//
//  ContentView.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import SwiftUI

/**
 主内容视图
 - View: 协议，所有SwiftUI视图都必须遵循
 - 类似Go中的interface，定义了视图的基本行为
 */
struct ContentView: View {
    /**
     @StateObject: 属性包装器，创建并拥有ObservableObject
     - 类似Go中创建结构体实例，但会自动管理生命周期
     - 当authManager的@Published属性变化时，UI会自动更新
     */
    @StateObject private var authManager = AuthManager()
    
    /**
     body: 计算属性，必须实现
     - 返回some View: 不透明类型，表示返回某种遵循View协议的类型
     - 类似Go中的interface{}，但更类型安全
     */
    var body: some View {
        /**
         Group: 容器视图，用于包装多个视图
         - 不会在UI中显示，只是逻辑分组
         */
        Group {
            /**
             条件渲染 - 添加动画过渡
             - 根据登录状态显示不同视图
             - 类似Go中的if-else，但更声明式
             - 添加动画让界面切换更流畅
             */
            if authManager.isLoggedIn {
                TodoListView()     // 已登录：显示TODO列表
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView()        // 未登录：显示登录界面
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isLoggedIn) // 添加动画
        /**
         .environmentObject(): 环境对象注入
         - 将authManager注入到子视图的环境中
         - 子视图可以通过@EnvironmentObject访问
         - 类似Go中的context传递，但更方便
         */
        .environmentObject(authManager)
    }
}

/**
 #Preview: 预览宏
 - Xcode会显示此视图的实时预览
 - 类似测试代码，但用于UI预览
 */
#Preview {
    // 1. 手动创建一个 AuthManager 的实例，专门给预览用
    let authManager = AuthManager()
    // 2. 将这个实例作为 environmentObject 注入到 ContentView 中
    //    这模拟了你在主 App 文件 (LoversCanteenApp.swift) 中的做法
    return ContentView()
        .environmentObject(authManager)
}
