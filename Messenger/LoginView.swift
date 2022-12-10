//
//  ContentView.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/7/22.
//

import SwiftUI
import Firebase

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var showImagePicker = false
    @State var loginStatusMessage = ""
    @State var image: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        
                        Text("Login")
                            .tag(true)
                        
                        Text("Create Account")
                            .tag(false)
                        
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            showImagePicker.toggle()
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 70))
                                        .padding()
                                        .foregroundColor(.black)
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 70)
                                .stroke(.black, lineWidth: 5)
                            )
                            
                        }
                    }
                    
                    Group {
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                        
                    }
                    .padding(15)
                    .background(.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 15, weight: .semibold))
                            
                            Spacer()
                            
                        }
                        .background(.red)
                        
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
                
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(image: $image)
                .ignoresSafeArea()
        }
    }
    
    func handleAction() {
        if isLoginMode {
            print("😎 Logged into Firebase with existing credentials")
            login()
        } else {
            createNewAccount()
            print("😎 Registered a new user inside of Firebase Auth")
        }
    }
    
    func login() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("😡 Failed to login user: \(err)")
                self.loginStatusMessage = "😡 Failed to login user: \(err)"
                return
            }
            
            print("😎 Successfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "😎 Successfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("😡 Failed to create user: \(err)")
                self.loginStatusMessage = "😡 Failed to create user: \(err)"
                return
            }
            
            print("😎 Successfully created user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "😎 Successfully created user: \(result?.user.uid ?? "")"
            
            self.imageToStorage()
        }
    }
    
    func imageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let storageRef = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        storageRef.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "😡 Failed to push image to Storage: \(err)"
                return
            }
            
            storageRef.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "😡 Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "😎 Successfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString ?? "")
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                print("😎 Success")
                self.didCompleteLoginProcess()
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}

