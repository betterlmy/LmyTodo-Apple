//
//  LoginView.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import SwiftUI

/**
 登录视图
 - 支持登录和注册功能
 - 使用状态管理响应用户交互
 */
struct LoginView: View {
    // MARK: - 状态管理
    
    /**
     @EnvironmentObject: 从环境中获取共享的ObservableObject
     - 使用ContentView中注入的authManager实例
     - 这样登录状态变化会在整个应用中共享
     */
    @EnvironmentObject var authManager: AuthManager
    
    /**
     @State: 本地状态管理
     - 类似Go中的局部变量，但会触发UI更新
     - private: 只在当前视图内使用
     */
    @State private var username = ""        // 用户名输入
    @State private var password = ""        // 密码输入
    @State private var email = ""           // 邮箱输入（注册时使用）
    @State private var isRegistering = false // 是否处于注册模式
    @State private var showingAlert = false  // 是否显示错误弹窗
    @State private var showingSuccessAlert = false // 是否显示成功弹窗
    
    // MARK: - 视图主体
    
    /**
     body: 计算属性，返回视图内容
     - some View: 不透明类型，表示返回某种遵循View协议的类型
     */
    var body: some View {
        /**
         NavigationView: 导航容器
         - 提供导航栏和标题功能
         - 类似Android的ActionBar或iOS的NavigationController
         */
        NavigationView {
            /**
             ScrollView: 可滚动视图
             - 包裹VStack以支持内容超出屏幕时滚动
             */
            ScrollView {
                /**
                 VStack: 垂直堆栈布局
                 - spacing: 子视图间距
                 - 类似CSS的flex-direction: column
                 */
                VStack(spacing: 20) {
                    // MARK: - Logo和标题区域
                    /**
                     Logo和标题区域
                     */
                    logoSection
                    
                    // MARK: - 输入框区域
                    /**
                     输入框区域
                     */
                    inputSection
                    
                    // MARK: - 按钮区域
                    /**
                     按钮区域
                     */
                    buttonSection
                    
                    Spacer()  // 占位符，推动内容向上
                }
                .padding()
            }
            .navigationTitle(isRegistering ? "注册" : "登录")  // 动态标题
            
            // MARK: - 错误处理
            
            /**
             alert: 弹窗修饰符
             - isPresented: 绑定显示状态
             - 当showingAlert为true时显示弹窗
             */
            .alert("错误", isPresented: $showingAlert) {
                Button("确定") { }  // 确定按钮
            } message: {
                /**
                 ?? : 空合并操作符
                 - 如果authManager.errorMessage为nil，使用空字符串
                 */
                Text(authManager.errorMessage ?? "")
            }
            
            /**
             onChange: 监听数据变化
             - 当authManager.errorMessage改变时执行闭包
             - oldValue, newValue: 旧值和新值参数
             */
            .onChange(of: authManager.errorMessage) { _, errorMessage in
                showingAlert = errorMessage != nil  // 有错误时显示弹窗
            }
            
            // MARK: - 注册成功处理
            
            /**
             注册成功弹窗
             */
            .alert("注册成功", isPresented: $showingSuccessAlert) {
                Button("确定") {
                    // 清除成功消息
                    authManager.clearRegisterSuccessMessage()
                    // 切换到登录模式
                    isRegistering = false
                    // 清空输入字段
                    clearFields()
                }
            } message: {
                Text(authManager.registerSuccessMessage ?? "")
            }
            
            /**
             监听注册成功消息变化
             */
            .onChange(of: authManager.registerSuccessMessage) { _, successMessage in
                showingSuccessAlert = successMessage != nil
            }
        }
    }
    
    // MARK: - 子视图组件
    
    /**
     Logo和标题区域
     */
    private var logoSection: some View {
        VStack {
            /**
             Image: 图片视图
             - systemName: 使用系统内置图标
             - Swift的链式调用修饰符模式
             */
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))        // 设置图标大小
                .foregroundStyle(.blue)         // 设置颜色
            
            Text("Lmy TODO List")
                .font(.largeTitle)              // 大标题字体
                .fontWeight(.bold)              // 粗体
                .foregroundStyle(.primary)      // 主要颜色（适配深色模式）
            
            Text("管理我自己的任务")
                .font(.subheadline)             // 副标题字体
                .foregroundStyle(.secondary)    // 次要颜色
        }
        .padding(.bottom, 30)                   // 底部边距
    }
    
    /**
     输入框区域
     */
    private var inputSection: some View {
        VStack(spacing: 15) {
            // spacing 15是子视图间距
            /**
             条件渲染 - 注册时显示邮箱输入
             */
            if isRegistering {
                TextField("邮箱", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            /**
             TextField: 文本输入框
             - text: $username: 双向数据绑定，$表示binding
             - 当用户输入时，username变量会自动更新
             - 当username变量改变时，输入框显示会自动更新
             */
            TextField("用户名", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            /**
             SecureField: 密码输入框
             - 自动隐藏输入内容
             */
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)                   // 水平边距
    }
    
    /**
     按钮区域
     */
    private var buttonSection: some View {
        VStack(spacing: 15) {
            /**
             Button: 按钮视图
             - action: 点击事件闭包
             - label: 按钮外观
             */
            // 计算按钮禁用状态
            let isDisabled = username.isEmpty || password.isEmpty || (isRegistering && email.isEmpty) || authManager.isLoading
            
            Button(action: {
                // 根据当前模式执行不同操作
                if isRegistering {
                    authManager.register(username: username, email: email, password: password)
                } else {
                    authManager.login(username: username, password: password)
                }
            }) {
                /**
                 按钮样式设计 - 添加加载状态
                 - frame: 设置尺寸
                 - background: 背景色（根据禁用状态动态变化）
                 - cornerRadius: 圆角
                 */
                HStack {
                    // HStack 是水平堆叠视图
                    if authManager.isLoading {
                        ProgressView()  // 加载指示器
                            .scaleEffect(0.8) // 缩放效果22
                            .foregroundStyle(.white)
                    }
                    Text(authManager.isLoading ? "处理中,不要急哦" : (isRegistering ? "注册" : "登录"))
                        .font(.headline) // 标题字体
                }
                .foregroundStyle(.white) // 文字颜色
                .frame(maxWidth: .infinity)     // 最大宽度 infinity 是指无限制宽度
                .padding()  // 内边距
                .background(isDisabled ? Color.gray : Color.blue)  // 禁用时显示灰色
                .cornerRadius(10) // 圆角
            }
            /**
             disabled: 禁用条件
             - 使用统一的 isDisabled 变量
             */
            .disabled(isDisabled)
            
            /**
             注册/登录切换模式按钮
             */
            Button(action: {
                isRegistering.toggle()  // 切换布尔值
                clearFields()           // 清空输入字段
            }) {
                Text(isRegistering ? "已有账号？点击登录" : "没有账号？点击注册")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal) // 水平边距
    }
    
    // MARK: - 私有方法
    
    /**
     清空输入字段
     - 私有函数，只在当前视图内使用
     */
    private func clearFields() {
        username = ""
        password = ""
        email = ""
    }
}

/**
 预览宏
 - 在Xcode中显示实时预览
 - 用于开发时快速查看UI效果
 - 需要提供AuthManager环境对象
 */
#Preview {
    LoginView()
        .environmentObject(AuthManager()) // 为预览提供AuthManager实例
}
