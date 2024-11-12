// User.swift
struct User: Identifiable {
    let id: String
    let name: String
    let lastMessage: String?
    let lastMessageTime: Date?
    
    init(id: String, name: String, lastMessage: String? = nil, lastMessageTime: Date? = nil) {
        self.id = id
        self.name = name
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
    }
}