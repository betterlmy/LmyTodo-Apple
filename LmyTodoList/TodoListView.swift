//
//  TodoListView.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import SwiftUI

struct TodoListView: View {
    @StateObject private var todoManager = TodoManager()
    @EnvironmentObject var authManager: AuthManager  // 使用环境中的AuthManager
    @State private var showingAddTodo = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if todoManager.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if todoManager.todos.isEmpty {
                    VStack {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无任务")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("点击右上角的 + 添加新任务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(todoManager.todos) { todo in
                            TodoRowView(todo: todo, todoManager: todoManager)
                        }
                        .onDelete(perform: deleteTodos)
                    }
                }
            }
            .navigationTitle("我的任务")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Button("用户信息") {
                            // 可以添加用户信息视图
                        }
                        Button("退出登录") {
                            authManager.logout()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddTodo = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                todoManager.loadTodos()
            }
            .onAppear {
                todoManager.loadTodos()
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView(todoManager: todoManager)
            }
            .alert("错误", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(todoManager.errorMessage ?? "")
            }
            .onChange(of: todoManager.errorMessage) { _, errorMessage in
                showingAlert = errorMessage != nil
            }
        }
    }
    
    private func deleteTodos(offsets: IndexSet) {
        for index in offsets {
            let todo = todoManager.todos[index]
            todoManager.deleteTodo(id: todo.id)
        }
    }
}

struct TodoRowView: View {
    let todo: Todo
    let todoManager: TodoManager
    
    var body: some View {
        HStack {
            Button(action: {
                todoManager.toggleTodoCompletion(todo: todo)
            }) {
                Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.completed ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .strikethrough(todo.completed)
                    .foregroundColor(todo.completed ? .secondary : .primary)
                
                if !todo.description.isEmpty {
                    Text(todo.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(todo.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    TodoListView()
        .environmentObject(AuthManager()) // 为预览提供AuthManager实例
}
