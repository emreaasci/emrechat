//
//  MainViewModel.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//


import Foundation
import SwiftUI
import CoreData

class MainViewModel: ObservableObject {
    @Published var users: [User] = []
    let currentUserId: String
    let socketManager: SocketManager
    private let context: NSManagedObjectContext
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        self.socketManager = SocketManager()
        self.context = PersistenceController.shared.container.viewContext
        
        loadUsers()
        
        socketManager.onReceive = { [weak self] message in
            DispatchQueue.main.async {
                print("Ana ekranda yeni mesaj alındı: \(message.id)")
                // Mesajı CoreData'ya kaydet
                self?.saveMessage(message)
                // UI'ı güncelle
                self?.handleNewMessage(message)
            }
        }
        
        socketManager.connect(userId: currentUserId)
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
            print("MainViewModel: Mesaj CoreData'ya kaydedildi - ID: \(message.id)")
        } catch {
            print("MainViewModel: Mesaj kaydetme hatası: \(error)")
        }
    }
    
    private func loadUsers() {
        // Önce kullanıcıları yükle
        let baseUsers = [
            User(id: "user1", name: "Kullanıcı 1"),
            User(id: "user2", name: "Kullanıcı 2"),
            User(id: "user3", name: "Kullanıcı 3")
        ].filter { $0.id != currentUserId }
        
        // Her kullanıcı için son mesajı bul
        users = baseUsers.map { user in
            let lastMessage = fetchLastMessage(for: user.id)
            return User(
                id: user.id,
                name: user.name,
                lastMessage: lastMessage?.content,
                lastMessageTime: lastMessage?.timestamp
            )
        }
    }
    
    private func fetchLastMessage(for userId: String) -> CDChatMessage? {
        let request = NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
        let predicate = NSPredicate(format: "(fromUserId == %@ AND toUserId == %@) OR (fromUserId == %@ AND toUserId == %@)",
                                  currentUserId, userId, userId, currentUserId)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChatMessage.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let messages = try context.fetch(request)
            return messages.first
        } catch {
            print("Son mesaj getirme hatası: \(error)")
            return nil
        }
    }
    
    private func handleNewMessage(_ message: ChatMessage) {
        // Mesaj gönderen veya alıcı kullanıcıyı bul
        let relevantUserId = message.from == currentUserId ? message.to : message.from
        
        if let index = users.firstIndex(where: { $0.id == relevantUserId }) {
            var updatedUser = users[index]
            updatedUser = User(
                id: updatedUser.id,
                name: updatedUser.name,
                lastMessage: message.content,
                lastMessageTime: message.timestamp
            )
            users[index] = updatedUser
            
            // Bildirim göster (sadece gelen mesajlar için)
            if message.from != currentUserId {
                showNotification(from: updatedUser.name, message: message.content)
            }
        }
    }
    
    private func showNotification(from sender: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = sender
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim hatası: \(error)")
            }
        }
    }
}
