//
//  ChatMessage.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

// ChatMessage.swift
import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let from: String
    let to: String
    let content: String
    let timestamp: Date
    var status: MessageStatus
    
    var isFromCurrentUser: Bool {
        UserDefaults.standard.string(forKey: "currentUserId") == from
    }
    
    enum MessageStatus: String, Codable, Equatable {
        case sent = "sent"
        case delivered = "delivered"
        case read = "read"
    }
    
    init?(from cdMessage: CDChatMessage) {
        guard let id = cdMessage.id,
              let type = cdMessage.type,
              let from = cdMessage.fromUserId,
              let to = cdMessage.toUserId,
              let content = cdMessage.content,
              let timestamp = cdMessage.timestamp,
              let statusRaw = cdMessage.status,
              let status = MessageStatus(rawValue: statusRaw) else {
            return nil
        }
        
        self.id = id
        self.type = type
        self.from = from
        self.to = to
        self.content = content
        self.timestamp = timestamp
        self.status = status
    }
    
    init(id: String = UUID().uuidString,
         type: String = "message",
         from: String,
         to: String,
         content: String,
         timestamp: Date = Date(),
         status: MessageStatus = .sent) {
        self.id = id
        self.type = type
        self.from = from
        self.to = to
        self.content = content
        self.timestamp = timestamp
        self.status = status
    }
}
