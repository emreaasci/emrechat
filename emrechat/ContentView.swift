// ContentView.swift
struct ContentView: View {
    let currentUserId: String
    let recipientId: String
    
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    
    init(currentUserId: String, recipientId: String) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            currentUserId: currentUserId,
            recipientId: recipientId
        ))
    }
    
    var body: some View {
        VStack {
            List(viewModel.messages, id: \.content) { message in
                HStack {
                    if message.from == currentUserId {
                        Spacer()
                        Text(message.content)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text(message.content)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                        Spacer()
                    }
                }
            }
            
            HStack {
                TextField("Mesaj...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Gönder") {
                    viewModel.sendMessage(messageText)
                    messageText = ""
                }
                .padding(.trailing)
                .disabled(messageText.isEmpty)
            }
            .padding(.vertical)
        }
        .navigationTitle("Sohbet")
    }
}