# Socialbase

 [![Version](http://img.shields.io/cocoapods/v/Socialbase.svg)](http://cocoapods.org/?q=Socialbase)
 [![Platform](http://img.shields.io/cocoapods/p/Socialbase.svg)](http://cocoapods.org/?q=Socialbase)
 [![Downloads](https://img.shields.io/cocoapods/dt/Socialbase.svg?label=Total%20Downloads&colorB=28B9FE)](https://cocoapods.org/pods/Socialbase)

Socialbase is a framework for building SNS in Cloud Firestore.


## Requirements ❗️
- iOS 10 or later
- Swift 4.0 or later
- [Firebase firestore](https://firebase.google.com/docs/firestore/quickstart)
- [Cocoapods](https://github.com/CocoaPods/CocoaPods/milestone/32) 1.4 ❗️  ` gem install cocoapods`

## Installation ⚙
#### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'Socialbase' ` to your Podfile.
- Run `pod install`.

## Usage

Make your User defined by [Pring](https://github.com/1amageek/Pring) compliant with Socialbase.

```swift
@objcMembers
final class User: Object, Socialbase {

    dynamic var name: String = "USER_NAME"
    dynamic var type: String = UserType.none.rawValue

    // Organizable
    let organizations: ReferenceCollection<User> = []
    let peoples: ReferenceCollection<User> = []
    
    // Followable
    let followers: ReferenceCollection<User> = []
    let followees: ReferenceCollection<User> = []
}
```

```swift
extension User {
    typealias Invitation = Test.Invitation
}

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
```

```swift
extension User {
    typealias FollowRequest = Test.FollowRequest
}

extension Test {
    @objcMembers
    class FollowRequest: Object, FollowRequestProtocol {
        typealias Element = User
        dynamic var status: String = Status.none.rawValue
        dynamic var message: String?
        dynamic var toID: String = ""
        dynamic var fromID: String = ""
    }
}
```

Invite users to your organization.

```swift
let user0: User = User(id: "user0", value: [:]) // Organization user
let user1: User = User(id: "user1", value: [:])
let invitation: Test.Invitation = Test.Invitation(fromID: user0.id, toID: user1.id)
invitation.save()
```

Following users.

```swift
let user0: User = User(id: "user0", value: [:])
let user0: User = User(id: "user1", value: [:])
user1.follow(from: user0)
```
