// ChatMessage.swift
struct ChatMessage: Codable {
    let type: String
    let from: String
    let to: String
    let content: String
}