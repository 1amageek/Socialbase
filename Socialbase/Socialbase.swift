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

public typealias Socialbase = OrganizationDocument & UserDocument

public protocol UserProtocol: Document { }
public protocol OrganizationProtocol: Document { }

public typealias OrganizationDocument = OrganizationProtocol & Organizable
public typealias UserDocument = UserProtocol & Joinable

/// The protocol that the document to be invited conforms to.
public protocol Invitable: Document {
    associatedtype Invitation: InvitationProtocol
    var invitations: DataSource<Invitation>.Query { get }
}

extension Invitable {
    public var invitations: DataSource<Invitation>.Query {
        return Invitation.query.where(\Invitation.userID, isEqualTo: self.id)
    }
}

/// The protocol to which the document issuing the invitation should conform.
public protocol Issuable: Document {
    associatedtype Invitation: InvitationProtocol
    var issuedInvitations: DataSource<Invitation>.Query { get }
}

extension Issuable {
    public var issuedInvitations: DataSource<Invitation>.Query {
        return Invitation.query.where(\Invitation.organizationID, isEqualTo: self.id)
    }
}

/// The protocol that the Document that can participate in the organization should conform.
public protocol Joinable: Invitable {
    associatedtype Organization: OrganizationProtocol
    var organizations: ReferenceCollection<Organization> { get }
}

/// Protocol to which an organizable Document should conform.
public protocol Organizable: Issuable {
    associatedtype People: UserProtocol
    var peoples: ReferenceCollection<People> { get }
}

// MARK: - Invitation

public protocol InvitationProtocol: Document {
    associatedtype Organization: OrganizationDocument
    associatedtype People: UserDocument
    var status: String { get set }
    var message: String { get set }
    var userID: String { get set }
    var organizationID: String { get set }
    init(userID: String, organizationID: String)
}

public extension InvitationProtocol where
    Self: Object, Organization: Object, People: Object,
    Organization.People == People, People.Organization == Organization,
    Organization.Invitation == Self, People.Invitation == Self {

    public init(userID: String, organizationID: String) {
        self.init(id: organizationID)
        self.status = Status.none.rawValue
        self.userID = userID
        self.organizationID = organizationID
    }

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let organization: Organization = Organization(id: self.id, value: [:])
        let user: People = People(id: self.userID, value: [:])
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

// MARK: - FollowRequest

public protocol Followable: Document {
    associatedtype User: UserProtocol
    var followers: ReferenceCollection<User> { get }
    var followees: ReferenceCollection<User> { get }
}

public protocol FollowRequestProtocol: Document {
    associatedtype User: UserProtocol
    var status: String { get set }
    var fromID: String { get set }
    var toID: String { get set }
    init(fromID: String, toID: String)
}

public extension FollowRequestProtocol where Self: Object, User: Object, User: Followable, User.User == User {

    public init(fromID: String, toID: String) {
        self.init(id: fromID)
        self.status = Status.none.rawValue
        self.fromID = fromID
        self.toID = toID
    }

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let follower: User = User(id: self.fromID, value: [:])
        let followee: User = User(id: self.toID, value: [:])
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

public extension Followable where Self: Object, User: Followable, User == Self {

    public func follow(from user: User, block: ((Error?) -> Void)? = nil) {
        self.followers.insert(user)
        user.followees.insert(self)
        self.update(block)
    }
}
