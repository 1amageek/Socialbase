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

//public typealias Socialbase = OrganizationDocument & UserDocument
//
//public protocol UserProtocol: Document { }
//public protocol OrganizationProtocol: Document { }

//public typealias OrganizationDocument = OrganizationProtocol & Organizable
//public typealias UserDocument = UserProtocol & Joinable
//
///// The protocol that the document to be invited conforms to.
//public protocol Invitable: Document {
//    associatedtype Request: InvitationProtocol
//    var invitations: DataSource<Request>.Query { get }
//}
//
//extension Invitable {
//    public var invitations: DataSource<Request>.Query {
//        return Request.query.where(\Request.toID, isEqualTo: self.id)
//    }
//}
//
///// The protocol to which the document issuing the invitation should conform.
//public protocol Issuable: Document {
//    associatedtype Request: InvitationProtocol
//    var issuedInvitations: DataSource<Request>.Query { get }
//}
//
//extension Issuable {
//    public var issuedInvitations: DataSource<Request>.Query {
//        return Request.query.where(\Request.fromID, isEqualTo: self.id)
//    }
//}
//
///// The protocol that the Document that can participate in the organization should conform.
//public protocol Joinable: Invitable {
//    associatedtype Organization: OrganizationProtocol
//    var organizations: ReferenceCollection<Organization> { get }
//}
//
///// Protocol to which an organizable Document should conform.
//public protocol Organizable: Issuable {
//    associatedtype People: UserProtocol
//    var peoples: ReferenceCollection<People> { get }
//}

// MARK: - Request

/// Protocol to which the request document should conform.
public protocol RequestProtocol: Document {
    var status: String { get set }
    var fromID: String { get set }
    var toID: String { get set }
    var message: String? { get set }
    init(fromID: String, toID: String)
}

public extension RequestProtocol {

    public init(fromID: String, toID: String) {
        self.init(id: fromID)
        self.status = Status.none.rawValue
        self.fromID = fromID
        self.toID = toID
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

public protocol InvitationProtocol: RequestProtocol {
    associatedtype Element: Organizable
}

/// The protocol that the document to be invited conforms to.
public protocol Invitable: Document {
    associatedtype Invitation: InvitationProtocol
    var invitations: DataSource<Invitation>.Query { get }
    var issuedInvitations: DataSource<Invitation>.Query { get }
}

extension Invitable {
    public var invitations: DataSource<Invitation>.Query {
        return Invitation.query.where("toID", isEqualTo: self.id)
    }
    public var issuedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where("fromID", isEqualTo: self.id)
    }
}

public extension InvitationProtocol where Self: Object {

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let organization: Element = Element(id: self.id, value: [:])
        let user: Element = Element(id: self.toID, value: [:])
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
    var followers: ReferenceCollection<Self> { get }
    var followees: ReferenceCollection<Self> { get }
}

public protocol FollowRequestProtocol: RequestProtocol {
    associatedtype Element: Followable
}

public extension FollowRequestProtocol where Self: Object {

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let follower: Element = Element(id: self.fromID, value: [:])
        let followee: Element = Element(id: self.toID, value: [:])
        follower.followees.insert(followee)
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

    public func follow(from user: Self, block: ((Error?) -> Void)? = nil) {
        self.followers.insert(user)
        user.followees.insert(self)
        self.update(block)
    }
}
