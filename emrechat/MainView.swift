//
//  MainView.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//


import Foundation
import SwiftUI

// MainView.swift
struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    let currentUserId: String
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        _viewModel = StateObject(wrappedValue: MainViewModel(currentUserId: currentUserId))
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.users) { user in
                NavigationLink(destination: ChatView(currentUserId: currentUserId, recipientId: user.id, recipientName: user.name)) {
                    UserRow(user: user)
                }
            }
            .navigationTitle("Sohbetler")
        }
    }
}
