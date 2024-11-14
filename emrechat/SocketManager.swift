// SocketManager.swift
import Foundation

// SocketManager.swift

import Foundation

import Foundation

class SocketManager {
    private var webSocket: URLSessionWebSocketTask?
    var onReceive: ((ChatMessage) -> Void)?
    var onMessageStatusUpdate: ((String, MessageStatus) -> Void)?
    private var userId: String?
    private var messageRetryQueue: [(message: [String: Any], attempts: Int)] = []
    private let maxRetryAttempts = 3
    
    enum MessageStatus: String {
        case sent = "sent"           // Tek gri tik
        case delivered = "delivered"  // İki gri tik
        case read = "read"           // İki mavi tik
    }
    
    func connect(userId: String) {
        self.userId = userId
        guard let url = URL(string: "ws://172.10.40.66:8070") else { return }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        sendAuthMessage(userId: userId)
        receiveMessage()
    }
    
    private func sendAuthMessage(userId: String) {
        let authMessage: [String: Any] = [
            "type": "auth",
            "userId": userId
        ]
        send(dictionary: authMessage)
    }
    
    func sendMessage(from: String, to: String, content: String) {
        let messageId = UUID().uuidString
        
        // Önce lokal mesaj objesi oluştur
        let chatMessage = ChatMessage(
            id: messageId,
            from: from,
            to: to,
            content: content,
            status: .sent
        )
        
        // Mesajı socket üzerinden gönder
        let message: [String: Any] = [
            "type": "message",
            "messageId": messageId,
            "from": from,
            "to": to,
            "content": content,
            "timestamp": Date().timeIntervalSince1970,
            "status": MessageStatus.sent.rawValue
        ]
        
        print("Gönderilecek mesaj:", message)
        send(dictionary: message)
        
        // Lokal mesajı UI'a gönder
        DispatchQueue.main.async {
            self.onReceive?(chatMessage)
        }
    }
    
    func sendMessageRead(messageId: String, from: String) {
        let readReceipt: [String: Any] = [
            "type": "messageRead",
            "messageId": messageId,
            "userId": userId ?? "",
            "from": from,
            "timestamp": Date().timeIntervalSince1970
        ]
        send(dictionary: readReceipt)
    }
    
    private func sendDeliveryReceipt(messageId: String, from: String) {
        let deliveryReceipt: [String: Any] = [
            "type": "messageDelivery",
            "messageId": messageId,
            "userId": userId ?? "",
            "from": from,
            "timestamp": Date().timeIntervalSince1970
        ]
        send(dictionary: deliveryReceipt)
    }
    
    private func send(dictionary: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON dönüşüm hatası")
            return
        }
        
        webSocket?.send(.string(jsonString)) { [weak self] error in
            if let error = error {
                print("Gönderme hatası:", error)
                if let message = dictionary["type"] as? String,
                   message == "message" {
                    self?.handleMessageSendFailure(dictionary)
                }
            } else {
                print("Mesaj başarıyla gönderildi")
            }
        }
    }
    
    private func handleMessageSendFailure(_ message: [String: Any]) {
        if let attempts = messageRetryQueue.first(where: { $0.message["messageId"] as? String == message["messageId"] as? String })?.attempts {
            if attempts < maxRetryAttempts {
                messageRetryQueue.append((message: message, attempts: attempts + 1))
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.retryFailedMessage(message)
                }
            }
        } else {
            messageRetryQueue.append((message: message, attempts: 1))
            retryFailedMessage(message)
        }
    }
    
    private func retryFailedMessage(_ message: [String: Any]) {
        send(dictionary: message)
    }
    
    func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Alınan mesaj:", text)
                    
                    guard let data = text.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let type = json["type"] as? String else {
                        print("JSON parse hatası")
                        return
                    }
                    
                    switch type {
                    case "message":
                        self?.handleIncomingMessage(json)
                    case "messageDelivery":
                        if let messageId = json["messageId"] as? String {
                            print("Mesaj iletildi bildirimi alındı - ID:", messageId)
                            DispatchQueue.main.async {
                                self?.onMessageStatusUpdate?(messageId, .delivered)
                            }
                        }
                    case "messageRead":
                        if let messageId = json["messageId"] as? String {
                            print("Mesaj okundu bildirimi alındı - ID:", messageId)
                            DispatchQueue.main.async {
                                self?.onMessageStatusUpdate?(messageId, .read)
                            }
                        }
                    default:
                        print("Bilinmeyen mesaj tipi:", type)
                    }
                    
                case .data:
                    print("Binary data alındı")
                @unknown default:
                    break
                }
                
                self?.receiveMessage()
                
            case .failure(let error):
                print("Alma hatası:", error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.receiveMessage()
                }
            }
        }
    }
    
    private func handleIncomingMessage(_ json: [String: Any]) {
        guard let messageId = json["messageId"] as? String,
              let from = json["from"] as? String,
              let to = json["to"] as? String,
              let content = json["content"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval else {
            print("Mesaj parse hatası")
            return
        }
        
        let chatMessage = ChatMessage(
            id: messageId,
            type: "message",
            from: from,
            to: to,
            content: content,
            timestamp: Date(timeIntervalSince1970: timestamp),
            status: .delivered
        )
        
        // Mesaj alındığında otomatik olarak delivered durumuna geçir ve bildir
        sendDeliveryReceipt(messageId: messageId, from: from)
        
        DispatchQueue.main.async {
            self.onReceive?(chatMessage)
        }
    }
    
    deinit {
        webSocket?.cancel(with: .goingAway, reason: nil)
    }
}
