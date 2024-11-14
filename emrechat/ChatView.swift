//  ContentView.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//
import Foundation
import SwiftUI
struct ChatView: View {
    let currentUserId: String
    let recipientId: String
    let recipientName: String
    let socketManager: SocketManager
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var messagesCount: Int = 0
    
    init(currentUserId: String, recipientId: String, recipientName: String, socketManager: SocketManager) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.socketManager = socketManager
        
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            currentUserId: currentUserId,
            recipientId: recipientId,
            context: PersistenceController.shared.container.viewContext,
            socketManager: socketManager
        ))
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: viewModel.messages.count) { newCount in
                    if newCount > messagesCount {
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                        messagesCount = newCount
                    }
                }
            }
            
            MessageInputView(text: $messageText) {
                if !messageText.isEmpty {
                    viewModel.sendMessage(messageText)
                    messageText = ""
                }
            }
        }
        .navigationTitle(recipientName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.viewAppeared()
        }
    }
}
