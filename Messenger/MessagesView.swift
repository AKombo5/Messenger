//
//  MessagesView.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/9/22.
//

import SwiftUI
import SDWebImageSwiftUI

struct MessagesView: View {
    
    @State var chatUser: ChatUser?
    @State var showNewMessageScreen = false
    @State var showLogOutOptions = false
    @State var showChatView = false
    @EnvironmentObject var messagesVM: MessagesViewModel
    private var chatVM = ChatViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 15) {
                    
                    WebImage(url: URL(string: messagesVM.chatUser?.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(50)
                        .overlay(RoundedRectangle(cornerRadius: 50)
                            .stroke(.black, lineWidth: 1))
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        let email = messagesVM.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "").capitalized ?? ""
                        Text(email)
                            .font(.system(size: 30, weight: .bold))
                        
                        HStack {
                            Circle()
                                .foregroundColor(.green)
                                .frame(width: 15, height: 15)
                            Text("online")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        showLogOutOptions.toggle()
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .actionSheet(isPresented: $showLogOutOptions) {
                    .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                        .destructive(Text("Sign Out"), action: {
                            Task {
                                print("handle sign out")
                                await messagesVM.signOut()
                            }
                        }),
                        .cancel()
                    ])
                }
                .fullScreenCover(isPresented: $messagesVM.isUserCurrentlyLoggedOut, onDismiss: nil) {
                    LoginView(didCompleteLoginProcess: {
                        self.messagesVM.isUserCurrentlyLoggedOut = false
                        self.messagesVM.getCurrentUser()
                        self.messagesVM.getRecentMessages()
                    })
                }
                
                ScrollView {
                    ForEach(messagesVM.recentMessages) { recentMessage in
                        VStack {
                            Button {
                                let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                                
                                self.chatUser = .init(data: ["email": recentMessage.email, "profileImageUrl": recentMessage.profileImageUrl, "uid": uid])
                                
                                self.chatVM.chatUser = self.chatUser
                                self.chatVM.getMessages()
                                self.showChatView.toggle()
                            } label: {
                                HStack(spacing: 20) {
                                    WebImage(url: URL(string: recentMessage.profileImageUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipped()
                                        .cornerRadius(70)
                                        .overlay(RoundedRectangle(cornerRadius: 70).stroke(.black, lineWidth: 1))
                                        .shadow(radius: 5)
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(recentMessage.username)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.leading)
                                        Text(recentMessage.text)
                                            .font(.system(size: 15))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    
                                    Text(recentMessage.timePassed)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                            Divider()
                                .padding(.vertical, 10)
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding(.bottom, 50)
                }
                
                NavigationLink("", isActive: $showChatView) {
                    ChatView()
                        .environmentObject(chatVM)
                }
            }
            .overlay(
                Button("New Message") {
                    showNewMessageScreen.toggle()
                }
                    .font(.system(size: 20, weight: .bold))
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                
                    .fullScreenCover(isPresented: $showNewMessageScreen) {
                        CreateNewMessageView(didSelectNewUser: { user in
                            print(user.email)
                            self.showChatView.toggle()
                            self.chatUser = user
                            self.chatVM.chatUser = user
                            self.chatVM.getMessages()
                        })
                        .environmentObject(CreateNewMessageViewModel())
                    }
                , alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
            .environmentObject(MessagesViewModel())
    }
}


