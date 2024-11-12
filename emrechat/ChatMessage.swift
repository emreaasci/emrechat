//
//  ChatMessage.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

import Foundation


// ChatMessage.swift - init metodunu güncelle
struct ChatMessage: Identifiable, Codable {
    let id: String
    let type: String
    let from: String
    let to: String
    let content: String
    let timestamp: Date
    
    var isFromCurrentUser: Bool {
        UserDefaults.standard.string(forKey: "currentUserId") == from
    }
    
    // CoreData için
    init?(from cdMessage: CDChatMessage) {
        guard let id = cdMessage.id,
              let type = cdMessage.type,
              let from = cdMessage.fromUserId,
              let to = cdMessage.toUserId,
              let content = cdMessage.content,
              let timestamp = cdMessage.timestamp else {
            return nil
        }
        
        self.id = id
        self.type = type
        self.from = from
        self.to = to
        self.content = content
        self.timestamp = timestamp
    }
    
    // Doğrudan init
    init(id: String = UUID().uuidString,
         type: String = "message",
         from: String,
         to: String,
         content: String,
         timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.from = from
        self.to = to
        self.content = content
        self.timestamp = timestamp
    }
}
