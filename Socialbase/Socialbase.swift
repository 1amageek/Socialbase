//
//  Socialbase.swift
//  Socialbase
//
//  Created by 1amageek on 2018/02/24.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import FirebaseFirestore
import Pring
import CoreData

public enum Status: String {
    case none       = "none"
    case approved   = "approved"
    case rejected   = "rejected"
}

public enum UserType: String {
    case none           = "none"
    case individual     = "individual"
    case organization   = "rganization"
}

public typealias Socialbase = Organizable & Invitable & Followable & FollowRequestable

// MARK: - Request

/// Protocol to which the request document should conform.
public protocol RequestProtocol: Document {
    associatedtype Element: Document
    var status: String { get set }
    var from: Relation<Element> { get set }
    var to: Relation<Element> { get set }
    var message: String? { get set }
    init(fromID: String, toID: String)
}

public extension RequestProtocol {

    public init(fromID: String, toID: String) {
        self.init(id: fromID)
        self.status = Status.none.rawValue
        self.from.set(Element(id: fromID, value: [:]))
        self.to.set(Element(id: toID, value: [:]))
    }
}

// MARK: - Organization

/// Protocol to which an organizable Document should conform.
public protocol Organizable: Document {
    var name: String { get set }
    var type: String { get set }
    var peoples: ReferenceCollection<Self> { get }
    var organizations: ReferenceCollection<Self> { get }
}

public protocol InvitationProtocol: RequestProtocol where Element: Organizable {

}

/// The protocol that the document to be invited conforms to.
public protocol Invitable: Document {
    associatedtype Invitation: InvitationProtocol
    var invitations: DataSource<Invitation>.Query { get }
    var issuedInvitations: DataSource<Invitation>.Query { get }
}

extension Invitable {
    public var invitations: DataSource<Invitation>.Query {
        return Invitation.query.where("to", isEqualTo: self.id)
    }
    public var issuedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where("from", isEqualTo: self.id)
    }
}

public extension InvitationProtocol where Self: Object {

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let organization: Element = Element(id: self.id, value: [:])
        let user: Element = Element(id: self.to.id!, value: [:])
        organization.peoples.insert(user)
        user.organizations.insert(organization)
        let batch: WriteBatch = Firestore.firestore().batch()
        organization.pack(.update, batch: batch)
        self.update(batch, block: block)
    }

    public func reject(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.rejected.rawValue
        self.update(block)
    }
}

// MARK: - Follow

public protocol Followable: Document {
    var followersCount: Int { set get }
    var followingCount: Int { set get }
    var followers: ReferenceCollection<Self> { get }
    var following: ReferenceCollection<Self> { get }
}

/// The protocol that the document to be invited conforms to.
public protocol FollowRequestable: Document {
    associatedtype FollowRequest: FollowRequestProtocol
    var followRequests: DataSource<FollowRequest>.Query { get }
    var issuedFollowRequests: DataSource<FollowRequest>.Query { get }
}

extension FollowRequestable {
    public var followRequests: DataSource<FollowRequest>.Query {
        return FollowRequest.query.where("to", isEqualTo: self.id)
    }
    public var issuedFollowRequests: DataSource<FollowRequest>.Query {
        return FollowRequest.query.where("from", isEqualTo: self.id)
    }
}

public protocol FollowRequestProtocol: RequestProtocol where Element: Followable {

}

public extension FollowRequestProtocol where Self: Object {

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let follower: Element = Element(id: self.from.id!, value: [:])
        let followee: Element = Element(id: self.to.id!, value: [:])
        follower.following.insert(followee)
        followee.followers.insert(follower)
        let batch: WriteBatch = Firestore.firestore().batch()
        follower.pack(.update, batch: batch)
        self.update(batch, block: block)
    }

    public func reject(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.rejected.rawValue
        self.update(block)
    }
}

public extension Followable where Self: Object {

    public func follow(from user: Self, block: ((Any?, Error?) -> Void)? = nil) {
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in

            let me: DocumentSnapshot
            let you: DocumentSnapshot
            do {
                try me = transaction.getDocument(self.reference)
                try you = transaction.getDocument(user.reference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            let followers = me.data()?["followersCount"] as? Int ?? 0

            let following = you.data()?["followingCount"] as? Int ?? 0

            transaction.updateData(["followersCount": followers + 1], forDocument: me.reference)
            transaction.updateData(["followingCount": following + 1], forDocument: you.reference)
            transaction.setData([
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: self.followers.reference.document(user.id))
            transaction.setData([
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: user.following.reference.document(self.id))

            return nil
        }) { (object, error) in
            block?(object, error)
        }
    }

    public func unfollow(from user: Self, block: ((Any?, Error?) -> Void)? = nil) {

        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in

            let me: DocumentSnapshot
            let you: DocumentSnapshot
            do {
                try me = transaction.getDocument(self.reference)
                try you = transaction.getDocument(user.reference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let followers = me.data()?["followersCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(me)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }

            guard let following = you.data()?["followingCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(me)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["followersCount": max(followers - 1, 0)], forDocument: me.reference)
            transaction.updateData(["followingCount": max(following - 1, 0)], forDocument: you.reference)
            transaction.deleteDocument(self.followers.reference.document(user.id))
            transaction.deleteDocument(user.following.reference.document(self.id))

            return nil
        }) { (object, error) in
            block?(object, error)
        }
    }
}
