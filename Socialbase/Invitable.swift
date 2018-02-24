//
//  Invitable.swift
//  Socialbase
//
//  Created by 1amageek on 2018/02/24.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import FirebaseFirestore
import Pring

//public protocol Invitable: Document {
//    associatedtype Organization: Organizable
//    var status: String { get set }
//    var message: String { get set }
//    var userID: String { get set }
//}
//
//extension Invitable where Self: Object {
//
//    public func approve(_ block: ((Error?) -> Void)? = nil) {
//        self.status = "approved"
//        let organization: Organization = Organization(id: self.id, value: [:])
//        let user: Organization.User = Organization.User(id: self.userID, value: [:])
//        organization.peoples.insert(user)
//        let batch: WriteBatch = Firestore.firestore().batch()
//        organization.pack(.update, batch: batch)
//        self.update(batch, block: block)
//    }
//
//    public func reject(_ block: ((Error?) -> Void)? = nil) {
//        self.status = "rejected"
//        self.update(block)
//    }
//}

