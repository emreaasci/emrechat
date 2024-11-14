//
//  MessageBubble.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    private func statusIcon(for status: ChatMessage.MessageStatus) -> some View {
        Group {
            switch status {
            case .sent:
                // Tek gri tik
                Image(systemName: "checkmark")
                    .foregroundColor(.gray)
            case .delivered:
                // İki gri tik
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .foregroundColor(.gray)
            case .read:
                // İki mavi tik
                HStack(spacing: -4) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .foregroundColor(.blue)
            }
        }
        .font(.caption2)
        .id("\(message.id)-\(status.rawValue)") // Force view güncelleme için
        .animation(.easeInOut, value: status)
    }
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(BubbleShape(isFromCurrentUser: true))
                    
                    HStack(spacing: 4) {
                        Text(timeString(from: message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        statusIcon(for: message.status)
                            .id("\(message.id)-status") // Force view güncelleme için
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .clipShape(BubbleShape(isFromCurrentUser: false))
                    
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
