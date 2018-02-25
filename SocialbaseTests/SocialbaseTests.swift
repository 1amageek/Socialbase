//
//  SocialbaseTests.swift
//  SocialbaseTests
//
//  Created by 1amageek on 2018/02/25.
//  Copyright © 2018年 Stamp Inc. All rights reserved.
//

import XCTest
@testable import Socialbase
import Firebase
import FirebaseFirestore
import FirebaseStorage
import Pring

class FirebaseTest {

    static let shared: FirebaseTest = FirebaseTest()

    init () {
        FirebaseApp.configure()
    }

}

class SocialbaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        _ = FirebaseTest.shared
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrganizableWhenInvitationApproved() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let invitation: Test.Invitation = Test.Invitation(fromID: user0.id, toID: user1.id)
                invitation.save { (_, _) in
                    Test.Invitation.get(user0.id, block: { (invitation, error) in
                        XCTAssertEqual(invitation?.fromID, user0.id)
                        XCTAssertEqual(invitation?.toID, user1.id)
                        XCTAssertEqual(invitation?.status, Status.none.rawValue)
                        invitation?.approve { _ in
                            Test.Invitation.get(user0.id, block: { (invitation, error) in
                                XCTAssertEqual(invitation?.fromID, user0.id)
                                XCTAssertEqual(invitation?.toID, user1.id)
                                XCTAssertEqual(invitation?.status, Status.approved.rawValue)
                                user0.delete()
                                user1.delete()
                                expectation.fulfill()
                            })
                        }
                    })
                }
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }

    func testOrganizableWhenInvitationRejected() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let invitation: Test.Invitation = Test.Invitation(fromID: user0.id, toID: user1.id)
                invitation.save { (_, _) in
                    Test.Invitation.get(user0.id, block: { (invitation, error) in
                        XCTAssertEqual(invitation?.fromID, user0.id)
                        XCTAssertEqual(invitation?.toID, user1.id)
                        XCTAssertEqual(invitation?.status, Status.none.rawValue)
                        invitation?.reject { _ in
                            Test.Invitation.get(user0.id, block: { (invitation, error) in
                                XCTAssertEqual(invitation?.fromID, user0.id)
                                XCTAssertEqual(invitation?.toID, user1.id)
                                XCTAssertEqual(invitation?.status, Status.rejected.rawValue)
                                user0.delete()
                                user1.delete()
                                expectation.fulfill()
                            })
                        }
                    })
                }
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }

    func testOrganizableWhenInvited() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let invitation: Test.Invitation = Test.Invitation(fromID: user0.id, toID: user1.id)
                invitation.save { (_, _) in
                    user0.issuedInvitations.dataSource().onCompleted({ (_, invitations) in
                        let invitation = invitations.first
                        XCTAssertEqual(invitation?.fromID, user0.id)
                        user1.invitations.dataSource().onCompleted({ (_, invitations) in
                            let invitation = invitations.first
                            XCTAssertEqual(invitation?.toID, user1.id)
                            expectation.fulfill()
                        }).get()
                    }).get()
                }
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }
}
