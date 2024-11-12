struct Message: Codable {
    let type: String
    let messageId: String?
    let from: String?
    let to: String?
    let content: String?
    let timestamp: Double?
}