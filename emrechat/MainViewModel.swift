//
//  MainViewModel.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//


import Foundation
import SwiftUI

// MainViewModel.swift
class MainViewModel: ObservableObject {
    @Published var users: [User] = []
    let currentUserId: String
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        loadUsers()
    }
    
    private func loadUsers() {
        // Örnek kullanıcılar - Gerçek uygulamada sunucudan gelecek
        users = [
            User(id: "user1", name: "Kullanıcı 1"),
            User(id: "user2", name: "Kullanıcı 2"),
            User(id: "user3", name: "Kullanıcı 3")
        ].filter { $0.id != currentUserId }
    }
}
