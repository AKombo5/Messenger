//
//  MessagesViewModel.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/8/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

@MainActor
class MessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    private var firestoreListener: ListenerRegistration?
    
    init() {
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        getCurrentUser()
        getRecentMessages()
    }
    
    func getRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection("recent_messages").document(uid).collection("messages").order(by: "timestamp").addSnapshotListener { querySnapshot, error in
            if let error = error {
                self.errorMessage = "😡 Failed to listen for recent messages: \(error)"
                print(error)
                return
            }
            
            querySnapshot?.documentChanges.forEach({ change in
                let docId = change.document.documentID
                
                if let index = self.recentMessages.firstIndex(where: { rm in
                    return rm.id == docId
                }) {
                    self.recentMessages.remove(at: index)
                }
                
                do {
                    if let rm = try change.document.data(as: RecentMessage?.self) {
                        self.recentMessages.insert(rm, at: 0)
                    }
                } catch {
                    print(error)
                }
                
            })
        }
    }
    
    func getCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "😡 Could not find firebase uid"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "😡 Failed to get current user: \(error)"
                print("😡 Failed to get current user:", error)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "😡 No data found"
                return
            }
            
            self.chatUser = .init(data: data)
        }
    }
    
    func signOut() async {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}


