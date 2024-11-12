// ChatViewModel.swift
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let socketManager = SocketManager()
    let currentUserId: String
    let recipientId: String
    
    init(currentUserId: String, recipientId: String) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        
        socketManager.onReceive = { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }
        
        socketManager.connect(userId: currentUserId)
    }
    
    func sendMessage(_ content: String) {
        socketManager.sendMessage(
            from: currentUserId,
            to: recipientId,
            content: content
        )
    }
}