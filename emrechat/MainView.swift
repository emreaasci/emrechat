//  MainView.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//
import Foundation
import SwiftUI
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
                NavigationLink(destination: ChatView(
                    currentUserId: currentUserId,
                    recipientId: user.id,
                    recipientName: user.name,
                    socketManager: viewModel.socketManager // SocketManager'ı geçir
                )) {
                    UserRow(user: user)
                }
            }
            .navigationTitle("Sohbetler")
        }
        .onAppear {
            // Bildirim izni iste
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Bildirim izni alındı")
                } else if let error = error {
                    print("Bildirim izni hatası: \(error)")
                }
            }
        }
    }
}
