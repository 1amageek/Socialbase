//
//  Invitation.swift
//  SocialbaseTests
//
//  Created by 1amageek on 2018/02/25.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Pring
import Socialbase

class Test {
    @objcMembers
    class Invitation: Object, InvitationProtocol {
        typealias Element = User
        dynamic var status: String = Status.none.rawValue
        dynamic var message: String?
        dynamic var toID: String = ""
        dynamic var fromID: String = ""
    }
}
