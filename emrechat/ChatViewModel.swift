//
//  ChatViewModel.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

import SwiftUI
import CoreData

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
        let currentUserId: String
        let recipientId: String
        private let context: NSManagedObjectContext
        private let socketManager: SocketManager
        
        init(currentUserId: String, recipientId: String, context: NSManagedObjectContext, socketManager: SocketManager) {
            self.currentUserId = currentUserId
            self.recipientId = recipientId
            self.context = context
            self.socketManager = socketManager
            
            UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
            
            loadMessages()
            
            socketManager.onReceive = { [weak self] message in
                if (message.from == self?.recipientId && message.to == self?.currentUserId) ||
                   (message.from == self?.currentUserId && message.to == self?.recipientId) {
                    DispatchQueue.main.async {
                        print("Yeni mesaj alındı: \(message.id)")
                        
                        // Check if message already exists
                        if !(self?.messages.contains(where: { $0.id == message.id }) ?? false) {
                            self?.saveMessage(message)
                            self?.messages.append(message)
                            
                            // If message is from recipient, mark as read since chat is open
                            if message.from == self?.recipientId {
                                print("Karşı taraftan gelen mesaj okundu olarak işaretleniyor: \(message.id)")
                                self?.socketManager.sendMessageRead(messageId: message.id, from: message.from)
                            }
                        }
                        
                        self?.objectWillChange.send()
                    }
                }
            }
            
            socketManager.onMessageStatusUpdate = { [weak self] messageId, status in
                DispatchQueue.main.async {
                    print("Mesaj durumu güncelleme bildirimi alındı - ID: \(messageId), Status: \(status.rawValue)")
                    self?.updateMessageStatus(messageId: messageId, status: status)
                }
            }
            
            // Mark messages as read when chat is opened
            markAllMessagesAsRead()
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
            newMessage.status = message.status.rawValue
            
            do {
                try context.save()
                print("Mesaj kaydedildi - ID: \(message.id)")
            } catch {
                print("Mesaj kaydetme hatası: \(error)")
            }
        }
    
    private func updateMessageStatus(messageId: String, status: SocketManager.MessageStatus) {
            print("Mesaj durumu güncelleniyor - ID: \(messageId), Yeni Durum: \(status.rawValue)")
            
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = messages[index]
                updatedMessage.status = ChatMessage.MessageStatus(rawValue: status.rawValue) ?? .sent
                messages[index] = updatedMessage
                
                // CoreData güncelleme
                let request = NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
                request.predicate = NSPredicate(format: "id == %@", messageId)
                
                do {
                    let results = try context.fetch(request)
                    if let messageToUpdate = results.first {
                        messageToUpdate.status = status.rawValue
                        try context.save()
                        print("CoreData'da mesaj durumu güncellendi - ID: \(messageId)")
                    }
                } catch {
                    print("CoreData güncelleme hatası:", error)
                }
                
                objectWillChange.send()
            }
        }
    
    func sendMessage(_ content: String) {
            socketManager.sendMessage(
                from: currentUserId,
                to: recipientId,
                content: content
            )
        }
    
    func printDebugInfo() {
        print("\n--- Debug Bilgileri ---")
        print("Toplam Mesaj Sayısı: \(messages.count)")
        for message in messages {
            print("ID: \(message.id)")
            print("Content: \(message.content)")
            print("Status: \(message.status.rawValue)")
            print("From: \(message.from)")
            print("To: \(message.to)")
            print("-------------------")
        }
    }
    
    private func markAllMessagesAsRead() {
            let unreadMessages = messages.filter { !$0.isFromCurrentUser && $0.status != .read }
            for message in unreadMessages {
                print("Okunmamış mesaj işaretleniyor - ID: \(message.id)")
                socketManager.sendMessageRead(messageId: message.id, from: message.from)
            }
        }
        
        func viewAppeared() {
            markAllMessagesAsRead()
        }
    
}
