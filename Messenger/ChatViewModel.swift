//
//  ChatViewModel.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/9/22.
//

import Foundation
import SwiftUI
import Firebase

@MainActor
class ChatViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    var chatUser: ChatUser?
    var firestoreListener: ListenerRegistration?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        getMessages()
    }
    
    func getMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        firestoreListener?.remove()
        chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection("messages").document(fromId).collection(toId).order(by: "timestamp").addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "😡 Failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            if let cm = try change.document.data(as: ChatMessage?.self) {
                                self.chatMessages.append(cm)
                                print("😎 Appending chatMessage in ChatView: \(Date())")
                            }
                        } catch {
                            print("😡 Failed to decode message: \(error)")
                        }
                    }
                })
                
                self.count += 1
            }
    }
    
    func send() async {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        let document = FirebaseManager.shared.firestore.collection("messages").document(fromId).collection(toId).document()
        let msg = ChatMessage(id: nil, fromId: fromId, toId: toId, text: chatText, timestamp: Date())
        try? document.setData(from: msg) { error in
            if let error = error {
                print(error)
                self.errorMessage = "😡 Failed to save message into Firestore: \(error)"
                return
            }
            
            print("😎 Successfully saved current user sending message")
            self.keepRecentMessage()
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages").document(toId).collection(fromId).document()
        
        try? recipientMessageDocument.setData(from: msg) { error in
            if let error = error {
                print(error)
                self.errorMessage = "😡 Failed to save message into Firestore: \(error)"
                return
            }
            
            print("😎 Recipient saved message")
        }
    }
    
    func keepRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection("recent_messages").document(uid).collection("messages").document(toId)
        
        let data = [
            "timestamp": Timestamp(),
            "text": self.chatText,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": chatUser.profileImageUrl,
            "email": chatUser.email
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "😡 Failed to save recent message: \(error)"
                print("😡 Failed to save recent message: \(error)")
                return
            }
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let recipientRecentMessageDictionary = [
            "timestamp": Timestamp(),
            "text": self.chatText,
            "fromId": uid,
            "toId": toId,
            "profileImageUrl": currentUser.profileImageUrl,
            "email": currentUser.email
        ] as [String : Any]
        
        FirebaseManager.shared.firestore.collection("recent_messages").document(toId).collection("messages").document(currentUser.uid).setData(recipientRecentMessageDictionary) { error in
                if let error = error {
                    print("😡 Failed to save recipient recent message: \(error)")
                    return
                }
            }
    }
}

