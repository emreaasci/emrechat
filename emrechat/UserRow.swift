//  UserRow.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//
import SwiftUI
// UserRow.swift
struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack {
            // Profil resmi placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.name.prefix(1))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                if let lastMessage = user.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let lastMessageTime = user.lastMessageTime {
                Text(timeString(from: lastMessageTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
