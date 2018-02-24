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
class User: Object {
    typealias Organization = User
    typealias People = User
    var organizations: ReferenceCollection<Organization> = []
    var peoples: ReferenceCollection<User> = []
}
