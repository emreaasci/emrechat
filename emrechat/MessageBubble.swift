struct MessageBubble: View {
    let message: ChatMessage
    
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
                    
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
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