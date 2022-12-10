//
//  CreateNewMessageView.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/9/22.
//

import SwiftUI
import SDWebImageSwiftUI

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var createNewMessageVM: CreateNewMessageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(createNewMessageVM.errorMessage)
                
                ForEach(createNewMessageVM.users) { user in
                    Button {
                        dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 15) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipped()
                                .cornerRadius(70)
                                .overlay(RoundedRectangle(cornerRadius: 70)
                                    .stroke(.black, lineWidth: 1))
                            
                            Text(user.email)
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewMessageView(
            didSelectNewUser: { user in
                print(user.email)
            }
        )
        .environmentObject(CreateNewMessageViewModel())
    }
}
