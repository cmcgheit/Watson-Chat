//
//  User.swift
//  Watson-Chat
//
//  Created by C McGhee on 6/26/17.
//  Copyright © 2017 C McGhee. All rights reserved.
//

import Foundation
import JSQMessagesViewController

enum User: String {
    // JSQMessage Cases
    case me = "053496-4509-288"
    case watson = "053496-4509-289"
    
    static func getName(_ user: User) -> String {
        switch user {
        case .me: return "Me"
        case .watson: return "Watson"
        }
    }
    
    static func getAvatar(_ id: String) -> JSQMessagesAvatarImage? {
        let user = User(rawValue: id)!
        switch user {
        case .me: return nil
        case .watson: return avatarWatson
        }
    }
}

private let avatarWatson = JSQMessagesAvatarImageFactory.avatarImage(
    with: #imageLiteral(resourceName: "watson-avatar"),
    diameter: 24
)
