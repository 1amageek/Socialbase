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
    case organization   = "organization"
}

public typealias Socialbase = Organizable & Issuable & Invitable & Followable & FollowRequestable

// MARK: - Request

/// Protocol to which the request document should conform.
public protocol RequestProtocol: Document {
    associatedtype Element: Document
    associatedtype Subject: Document
    var status: String { get set }
    var of: Relation<Subject> { get set }
    var from: Relation<Element> { get set }
    var to: Relation<Element> { get set }
    var message: String? { get set }

    /// init
    init(fromID: String, toID: String, ofID: String)

    /// This function approves the invitation.
    func approve(_ block: ((Error?) -> Void)?)

    /// This function rejects the invitation.
    func reject(_ block: ((Error?) -> Void)?)

    /// Cancel the invitation.
    func cancel(_ block: ((Error?) -> Void)?)
}

public extension RequestProtocol {

    public init(fromID: String, toID: String, ofID: String) {
        self.init()
        self.status = Status.none.rawValue
        self.from.set(Element(id: fromID, value: [:]))
        self.to.set(Element(id: toID, value: [:]))
        self.of.set(Subject(id: ofID, value: [:]))
    }

    public func cancel(_ block: ((Error?) -> Void)? = nil) {
        self.delete(block)
    }
}

public extension RequestProtocol where Self: Object, Subject == Element {

    public init(fromID: String, toID: String) {
        self.init()
        self.status = Status.none.rawValue
        self.from.set(Element(id: fromID, value: [:]))
        self.to.set(Element(id: toID, value: [:]))
        self.of.set(Subject(id: fromID, value: [:]))
    }
}

// MARK: - Organization

/// Protocol to which an organizable Document should conform.
public protocol Organizable: Document {

    /// User's name
    var name: String { get set }

    /// User type
    var type: String { get set }

    /// Users belonging to the organization
    var peoples: ReferenceCollection<Self> { get }

    /// Organization to which the user belongs
    var organizations: ReferenceCollection<Self> { get }
}

/// Invitation protocol.
public protocol InvitationProtocol: RequestProtocol { }

/// Make it compliant with issuable Subject.
public protocol Issuable: Document {
    associatedtype Invitation: InvitationProtocol
    var issuedInvitations: DataSource<Invitation>.Query { get }
}

extension Issuable {
    public var issuedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where("of", isEqualTo: self.id)
    }
}

/// The protocol that the document to be invited conforms to.
public protocol Invitable: Document {
    associatedtype Invitation: InvitationProtocol
    var invitedInvitations: DataSource<Invitation>.Query { get }
    var wasInvitedInvitations: DataSource<Invitation>.Query { get }
}

extension Invitable {
    public var invitedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where("from", isEqualTo: self.id)
    }
    public var wasInvitedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where("to", isEqualTo: self.id)
    }
}

public extension InvitationProtocol where Self: Object, Element: Organizable, Subject: Organizable {

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let from: Element = Element(id: self.from.id!, value: [:])
        let to: Element = Element(id: self.to.id!, value: [:])
        from.peoples.insert(to)
        to.organizations.insert(from)
        let batch: WriteBatch = Firestore.firestore().batch()
        from.pack(.update, batch: batch)
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

public protocol FollowRequestProtocol: RequestProtocol where Element: Followable, Element: FollowRequestable, Subject == Element {

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

public enum FollowableError: Error {
    case alreadyExists
    case doesNotExist
}

public extension Followable where Self: Object {

    public func follow(from user: Self, block: ((Any?, Error?) -> Void)? = nil) {
        self.followers.reference.document(user.id).getDocument { (snapshot, error) in
            if let error = error {
                block?(nil, error)
                return
            }
            if snapshot!.exists {
                let error: NSError = NSError(
                    domain: "AppErrorDomain",
                    code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "\(user.id) Already existis"
                    ])
                block?(nil, error)
            }
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
    }

    public func unfollow(from user: Self, block: ((Any?, Error?) -> Void)? = nil) {
        self.followers.reference.document(user.id).getDocument { (snapshot, error) in
            if let error = error {
                block?(nil, error)
                return
            }
            if !snapshot!.exists {
                let error: NSError = NSError(
                    domain: "AppErrorDomain",
                    code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "\(user.id) does not existis"
                    ])
                block?(nil, error)
            }
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
}
