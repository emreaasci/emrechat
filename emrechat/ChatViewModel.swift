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
                print("Yeni mesaj alındı: \(message.id)")
                self?.saveMessage(message)
                self?.messages.append(message)
                
                if !message.isFromCurrentUser {
                    print("Karşı taraftan gelen mesaj okundu olarak işaretleniyor: \(message.id)")
                    self?.socketManager.sendMessageRead(messageId: message.id, from: message.from)
                }
                
                self?.objectWillChange.send()
            }
        }
        
        socketManager.onMessageStatusUpdate = { [weak self] messageId, status in
            DispatchQueue.main.async {
                print("Mesaj durumu güncelleme bildirimi alındı - ID: \(messageId), Status: \(status.rawValue)")
                self?.updateMessageStatus(messageId: messageId, status: status)
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
        // Socket üzerinden gönder
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
}
