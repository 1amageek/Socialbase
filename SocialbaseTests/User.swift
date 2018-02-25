//
//  User.swift
//  SocialbaseTests
//
//  Created by 1amageek on 2018/02/25.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Pring
import Socialbase

@objcMembers
final class User: Object, Socialbase {

    dynamic var name: String = ""

    var type: String = UserType.none.rawValue
    
    var organizations: ReferenceCollection<User> = []
    var peoples: ReferenceCollection<User> = []

    var followers: ReferenceCollection<User> = []
    var followees: ReferenceCollection<User> = []
}

extension User {
    typealias Invitation = Test.Invitation
}
extension User {
    typealias FollowRequest = Test.FollowRequest
}
