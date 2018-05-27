//
//  FollowRequest.swift
//  SocialbaseTests
//
//  Created by 1amageek on 2018/02/25.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Pring
import Socialbase

extension Test {
    @objcMembers
    class FollowRequest: Object, FollowRequestProtocol {
        typealias Element = User
        typealias Subject = User
        dynamic var status: String = Status.none.rawValue
        dynamic var message: String?
        dynamic var of: Relation<Subject> = .init()
        dynamic var to: Relation<Element> = .init()
        dynamic var from: Relation<Element> = .init()
    }
}
