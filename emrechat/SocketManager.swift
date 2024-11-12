//
//  SocketManager.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

import  Foundation

// SocketManager.swift
import Foundation

class SocketManager {
    private var webSocket: URLSessionWebSocketTask?
    var onReceive: ((ChatMessage) -> Void)?
    private var userId: String?
    
    func connect(userId: String) {
        self.userId = userId
        guard let url = URL(string: "ws://172.20.10.10:8070") else { return }
        
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
        let message: [String: Any] = [
            "type": "message",
            "messageId": UUID().uuidString,
            "from": from,
            "to": to,
            "content": content,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        print("Gönderilecek mesaj:", message)
        send(dictionary: message)
    }
    
    private func send(dictionary: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON dönüşüm hatası")
            return
        }
        
        webSocket?.send(.string(jsonString)) { error in
            if let error = error {
                print("Gönderme hatası:", error)
            } else {
                print("Mesaj başarıyla gönderildi")
            }
        }
    }
    
    func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Alınan mesaj:", text)
                    
                    guard let data = text.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("JSON parse hatası")
                        return
                    }
                    
                    // Mesaj tipini kontrol et
                    guard let type = json["type"] as? String else { return }
                    
                    if type == "message" {
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
                            type: type,
                            from: from,
                            to: to,
                            content: content,
                            timestamp: Date(timeIntervalSince1970: timestamp)
                        )
                        
                        DispatchQueue.main.async {
                            self?.onReceive?(chatMessage)
                        }
                    }
                case .data:
                    print("Binary data alındı")
                @unknown default:
                    break
                }
                
                // Sürekli dinleme için tekrar çağır
                self?.receiveMessage()
                
            case .failure(let error):
                print("Alma hatası:", error)
                // Hata durumunda tekrar bağlanmayı dene
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.receiveMessage()
                }
            }
        }
    }
}
