//
//  ChatMessage.swift
//  Messenger
//
//  Created by Andrew Kombouras on 12/9/22.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}

