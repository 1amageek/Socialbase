//
//  Organizable.swift
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

public protocol UserProtocol: Document { }
public protocol OrganizationProtocol: Document { }

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
    associatedtype User: UserProtocol
    var peoples: ReferenceCollection<User> { get }
}

public protocol Followable: Document {
    associatedtype User: UserProtocol
    var followers: ReferenceCollection<User> { get }
    var followees: ReferenceCollection<User> { get }
}

public typealias OrganizationDocument = OrganizationProtocol & Organizable

public typealias UserDocument = UserProtocol & Joinable

public protocol InvitationProtocol: Document {
    associatedtype Organization: OrganizationDocument
    associatedtype User: UserDocument
    var status: String { get set }
    var message: String { get set }
    var userID: String { get set }
    var organizationID: String { get set }
    init(userID: String, organizationID: String)
}

public extension InvitationProtocol where
    Self: Object, Organization: Object, User: Object,
    Organization.User == User, User.Organization == Organization,
    Organization.Invitation == Self, User.Invitation == Self {

    public init(userID: String, organizationID: String) {
        self.init(id: organizationID)
        let invitation: Self = Self(id: organizationID)
        invitation.userID = userID
        invitation.organizationID = organizationID
    }

    public func approve(_ block: ((Error?) -> Void)? = nil) {
        self.status = Status.approved.rawValue
        let organization: Organization = Organization(id: self.id, value: [:])
        let user: User = User(id: self.userID, value: [:])
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

public extension Followable where Self: Object {

    public func follow<T: UserProtocol>(from user: T) {

    }

}
