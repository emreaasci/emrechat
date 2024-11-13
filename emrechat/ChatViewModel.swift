//
//  ChatViewModel.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

import SwiftUI
import Foundation
import CoreData


// ChatViewModel.swift
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let socketManager = SocketManager()
    let currentUserId: String
    let recipientId: String
    private let context: NSManagedObjectContext
    
    
    init(currentUserId: String, recipientId: String, context: NSManagedObjectContext) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        self.context = context
        
        UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
        
        loadMessages()
        
        socketManager.onReceive = { [weak self] message in
            DispatchQueue.main.async {
                self?.saveMessage(message)
                self?.messages.append(message)
            }
        }
        
        socketManager.connect(userId: currentUserId)
    }
    
    private func loadMessages() {
        let request = NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
        
        let predicate = NSPredicate(format: "(fromUserId == %@ AND toUserId == %@) OR (fromUserId == %@ AND toUserId == %@)",
                                  currentUserId, recipientId, recipientId, currentUserId)
        request.predicate = predicate
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChatMessage.timestamp, ascending: true)]
        
        do {
            let cdMessages = try context.fetch(request)
            messages = cdMessages.compactMap { cdMessage in
                ChatMessage(from: cdMessage)
            }
            print("Yüklenen mesaj sayısı: \(messages.count)")
        } catch {
            print("Mesajları yükleme hatası: \(error)")
        }
    }
    
    private func saveMessage(_ message: ChatMessage) {
        let newMessage = CDChatMessage(context: context)
        newMessage.id = message.id
        newMessage.type = message.type
        newMessage.content = message.content
        newMessage.fromUserId = message.from
        newMessage.toUserId = message.to
        newMessage.timestamp = message.timestamp
        
        do {
            try context.save()
            print("Mesaj kaydedildi: \(message.content)")
        } catch {
            print("Mesaj kaydetme hatası: \(error)")
        }
    }
    
    func sendMessage(_ content: String) {
        let message = ChatMessage(
            from: currentUserId,
            to: recipientId,
            content: content
        )
        
        socketManager.sendMessage(
            from: currentUserId,
            to: recipientId,
            content: content
        )
        
        DispatchQueue.main.async {
            self.saveMessage(message)
            self.messages.append(message)
        }
    }
}
