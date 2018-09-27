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
                    Test.Invitation
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let invitation: Test.Invitation = Test.Invitation(snapshot: document!)!
                            XCTAssertEqual(invitation.from.id, user0.id)
                            XCTAssertEqual(invitation.to.id, user1.id)
                            XCTAssertEqual(invitation.of.id, user0.id)
                            invitation.approve { _, _ in
                                Test.Invitation.get(invitation.id, block: { (invitation, error) in
                                    XCTAssertEqual(invitation?.from.id, user0.id)
                                    XCTAssertEqual(invitation?.to.id, user1.id)
                                    XCTAssertEqual(invitation?.of.id, user0.id)
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
                    Test.Invitation
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let invitation: Test.Invitation = Test.Invitation(snapshot: document!)!
                            XCTAssertEqual(invitation.from.id, user0.id)
                            XCTAssertEqual(invitation.to.id, user1.id)
                            XCTAssertEqual(invitation.of.id, user0.id)
                            invitation.reject { _ in
                                Test.Invitation.get(invitation.id, block: { (invitation, error) in
                                    XCTAssertEqual(invitation?.from.id, user0.id)
                                    XCTAssertEqual(invitation?.to.id, user1.id)
                                    XCTAssertEqual(invitation?.of.id, user0.id)
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

    func testOrganizableWhenInvitationCancelled() {
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
                    Test.Invitation
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let invitation: Test.Invitation = Test.Invitation(snapshot: document!)!
                            XCTAssertEqual(invitation.from.id, user0.id)
                            XCTAssertEqual(invitation.to.id, user1.id)
                            XCTAssertEqual(invitation.of.id, user0.id)
                            invitation.cancel { _ in
                                Test.Invitation.get(invitation.id, block: { (invitation, error) in
                                    XCTAssertNil(invitation, "Cancelled")
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
                        XCTAssertEqual(invitation?.from.id, user0.id)
                        user1.wasInvitedInvitations.dataSource().onCompleted({ (_, invitations) in
                            let invitation = invitations.first
                            XCTAssertEqual(invitation?.to.id, user1.id)
                            expectation.fulfill()
                        }).get()
                    }).get()
                }
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }

    func testFollowable() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                user1.follow(from: user0, block: { _, _ in
                    User.get(user0.id, block: { (_user0, _) in
                        XCTAssertEqual(_user0!.followingCount, 1)
                        User.get(user1.id, block: { (_user1, _) in
                            XCTAssertEqual(_user1!.followersCount, 1)
                            user1.followers.query.dataSource().onCompleted({ (snapshot, users) in
                                let user: User = users.first!
                                XCTAssertEqual(user.id, user0.id)
                                user0.following.query.dataSource().onCompleted({ (snapshot, users) in
                                    let user: User = users.first!
                                    XCTAssertEqual(user.id, user1.id)
                                    user1.unfollow(from: user0, block: { _, _ in
                                        User.get(user0.id, block: { (_user0, _) in
                                            XCTAssertEqual(_user0!.followingCount, 0)
                                            User.get(user1.id, block: { (_user1, _) in
                                                XCTAssertEqual(_user1!.followersCount, 0)
                                                user1.followers.query.dataSource().onCompleted({ (snapshot, users) in
                                                    XCTAssertEqual(users.count, 0)
                                                    user0.following.query.dataSource().onCompleted({ (snapshot, users) in
                                                        XCTAssertEqual(users.count, 0)
                                                        expectation.fulfill()
                                                    }).get()
                                                }).get()
                                            })
                                        })
                                    })
                                }).get()
                            }).get()
                        })
                    })
                })
            }
        }
        self.wait(for: [expectation], timeout: 15)
    }

    func testFollowableWhenRequestApproved() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let request: Test.FollowRequest = Test.FollowRequest(fromID: user0.id, toID: user1.id)
                request.save { (_, _) in
                    Test.FollowRequest
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let request: Test.FollowRequest = Test.FollowRequest(snapshot: document!)!
                            XCTAssertEqual(request.from.id, user0.id)
                            XCTAssertEqual(request.to.id, user1.id)
                            XCTAssertEqual(request.of.id, user0.id)
                            request.approve { _, _ in
                                Test.FollowRequest.get(request.id, block: { (request, error) in
                                    XCTAssertEqual(request?.from.id, user0.id)
                                    XCTAssertEqual(request?.to.id, user1.id)
                                    XCTAssertEqual(request?.status, Status.approved.rawValue)
                                    user1.followers.query.dataSource().onCompleted({ (snapshot, users) in
                                        let user: User = users.first!
                                        XCTAssertEqual(user.id, user0.id)
                                        user0.following.query.dataSource().onCompleted({ (snapshot, users) in
                                            let user: User = users.first!
                                            XCTAssertEqual(user.id, user1.id)
                                            user0.delete()
                                            user1.delete()
                                            expectation.fulfill()
                                        }).get()
                                    }).get()
                                })
                            }
                        })
                }
            }
        }
        self.wait(for: [expectation], timeout: 15)
    }

    func testFollowableWhenRequestRejected() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let request: Test.FollowRequest = Test.FollowRequest(fromID: user0.id, toID: user1.id)
                request.save { (_, _) in
                    Test.FollowRequest
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let request: Test.FollowRequest = Test.FollowRequest(snapshot: document!)!
                            XCTAssertEqual(request.from.id, user0.id)
                            XCTAssertEqual(request.to.id, user1.id)
                            XCTAssertEqual(request.of.id, user0.id)
                            request.reject { _ in
                                Test.FollowRequest.get(request.id, block: { (request, error) in
                                    XCTAssertEqual(request?.from.id, user0.id)
                                    XCTAssertEqual(request?.to.id, user1.id)
                                    XCTAssertEqual(request?.status, Status.rejected.rawValue)
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

    func testFollowableWhenRequestCancelled() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                let request: Test.FollowRequest = Test.FollowRequest(fromID: user0.id, toID: user1.id)
                request.save { (_, _) in
                    Test.FollowRequest
                        .where("from", isEqualTo: user0.id)
                        .where("to", isEqualTo: user1.id)
                        .get(completion: { (snapshot, _) in
                            let document = snapshot?.documents.first
                            let request: Test.FollowRequest = Test.FollowRequest(snapshot: document!)!
                            XCTAssertEqual(request.from.id, user0.id)
                            XCTAssertEqual(request.to.id, user1.id)
                            XCTAssertEqual(request.of.id, user0.id)
                            request.cancel { _ in
                                Test.FollowRequest.get(user0.id, block: { (invitation, error) in
                                    XCTAssertNil(invitation, "Cancelled")
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

    func testFollowableWhenFollow() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                user0.follow(from: user1, block: { (_, _) in
                    user0.follow(from: user1, block: { (_, error) in
                        if let error = error {
                            XCTAssertNotNil(error)
                        }
                        expectation.fulfill()
                    })
                })
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }

    func testFollowableWhenUnfollow() {
        let expectation: XCTestExpectation = XCTestExpectation()
        let user0: User = User()
        let user1: User = User()
        user0.name = "user0"
        user0.type = UserType.organization.rawValue
        user1.name = "user1"
        user0.save { (_, _) in
            user1.save { (_, _) in
                user0.unfollow(from: user1, block: { (_, error) in
                    if let error = error {
                        XCTAssertNotNil(error)
                    }
                    expectation.fulfill()
                })
            }
        }
        self.wait(for: [expectation], timeout: 10)
    }
}
