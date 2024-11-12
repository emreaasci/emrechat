// SocketManager.swift
class SocketManager {
    private var webSocket: URLSessionWebSocketTask?
    var onReceive: ((ChatMessage) -> Void)?
    
    func connect(userId: String) {
        // Kendi IP adresinizi buraya yazın
        guard let url = URL(string: "ws://localhost:8070") else { return }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // Auth mesajı gönder
        let authMessage = ["type": "auth", "userId": userId]
        send(dictionary: authMessage)
        
        receiveMessage()
    }
    
    private func send(dictionary: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        webSocket?.send(.string(jsonString)) { error in
            if let error = error {
                print("Gönderme hatası:", error)
            }
        }
    }
    
    func sendMessage(from: String, to: String, content: String) {
        let message = [
            "type": "message",
            "from": from,
            "to": to,
            "content": content
        ]
        send(dictionary: message)
    }
    
    func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                        self?.onReceive?(chatMessage)
                    }
                default:
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                print("Alma hatası:", error)
            }
        }
    }
}