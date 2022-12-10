//
//  ChatView.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/9/22.
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var chatVM: ChatViewModel
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    ForEach(chatVM.chatMessages) { message in
                        VStack {
                            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text(message.text)
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                                }
                            } else {
                                HStack {
                                    HStack {
                                        Text(message.text)
                                            .foregroundColor(.black)
                                    }
                                    .padding()
                                    .background(.white)
                                    .cornerRadius(8)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    HStack{ Spacer() }
                        .frame(height: 50)
                }
                .background(Color(.init(white: 0.95, alpha: 1)))
                .safeAreaInset(edge: .bottom) {
                    
                    HStack(spacing: 16) {
                        ZStack {
                            HStack {
                                Text("Message")
                                    .foregroundColor(Color(.gray))
                                    .font(.system(size: 20))
                                    .padding(.leading, 5)
                                    .padding(.bottom, 5)
                                    .italic()
                                
                                Spacer()
                            }
                            
                            TextEditor(text: $chatVM.chatText)
                                .opacity(chatVM.chatText.isEmpty ? 0.5 : 1)
                        }
                        .frame(height: 50)
                        
                        Button {
                            Task {
                                await chatVM.send()
                            }
                        } label: {
                            Text("Send")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.red)
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    .background(Color(.systemBackground).ignoresSafeArea())
                }
            }
            
            Text(chatVM.errorMessage)
        }
        .navigationTitle(chatVM.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            chatVM.firestoreListener?.remove()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView()
                .environmentObject(ChatViewModel(chatUser: nil))
        }
    }
}

