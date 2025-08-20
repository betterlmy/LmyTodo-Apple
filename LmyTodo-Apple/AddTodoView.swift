//
//  AddTodoView.swift
//  LoversCateen
//
//  Created by Zane on 2025/8/18.
//

import SwiftUI

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var todoManager: TodoManager
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务详情")) {
                    TextField("任务标题", text: $title)
                    
                    TextField("任务描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新建任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        todoManager.createTodo(title: title, description: description)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTodoView(todoManager: TodoManager())
}
