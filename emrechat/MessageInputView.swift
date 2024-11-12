// MessageInputView.swift
struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Mesaj yazın...", text: $text)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(text.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}