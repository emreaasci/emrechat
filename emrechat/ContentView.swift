//
//  ContentView.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//


import Foundation
import SwiftUI


struct ContentView: View {
    let currentUserId: String
    let recipientId: String
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    
    init(currentUserId: String, recipientId: String) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        
        // ViewContext'i shared instance'dan alıyoruz
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            currentUserId: currentUserId,
            recipientId: recipientId,
            context: PersistenceController.shared.container.viewContext
        ))
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                List(viewModel.messages, id: \.id) { message in
                    HStack {
                        if message.isFromCurrentUser {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Mesaj...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Gönder") {
                    viewModel.sendMessage(messageText)
                    messageText = ""
                }
                .padding(.trailing)
                .disabled(messageText.isEmpty)
            }
            .padding(.vertical)
        }
        .navigationTitle("Sohbet")
    }
}
