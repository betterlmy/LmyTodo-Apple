//
//  TodoManager.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import Foundation
import Combine

class TodoManager: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadTodos() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.getTodos()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] todos in
                    self?.todos = todos
                }
            )
            .store(in: &cancellables)
    }
    
    func createTodo(title: String, description: String) {
        NetworkManager.shared.createTodo(title: title, description: description)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newTodo in
                    self?.todos.insert(newTodo, at: 0)
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func updateTodo(id: Int, title: String? = nil, description: String? = nil, completed: Bool? = nil) {
        NetworkManager.shared.updateTodo(id: id, title: title, description: description, completed: completed)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    // 重新加载todos以获取最新状态
                    self?.loadTodos()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTodo(id: Int) {
        NetworkManager.shared.deleteTodo(id: id)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.todos.removeAll { $0.id == id }
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleTodoCompletion(todo: Todo) {
        updateTodo(id: todo.id, completed: !todo.completed)
    }
}
