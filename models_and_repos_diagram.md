# Fitbud Models and Repositories UML Diagram (Mermaid)

```mermaid
classDiagram
    %% Base Classes
    class FirestoreModel {
        <<abstract>>
        +String id
        +Map~String,dynamic~ toMap()
        +Timestamp? ts(DateTime? dt)$
        +DateTime? dt(Timestamp? ts)$
        +DateTime? readDate(dynamic v)$
        +int readInt(dynamic v)$
        +double readDouble(dynamic v)$
        +bool readBool(dynamic v)$
        +String readString(dynamic v)$
        +List~String~ readStringList(dynamic v)$
        +Map~String,dynamic~ readMap(dynamic v)$
    }

    %% Auth Models
    class AppUser {
        +String id
        +String? displayName
        +String? email
        +String? phone
        +String? photoUrl
        +bool isPremium
        +DateTime? premiumUntil
        +String? activePlanId
        +String? activeSubscriptionId
        +List~String~? activities
        +String? favouriteActivity
        +bool? hasGym
        +String? gymName
        +String? about
        +bool? isProfileComplete
        +String? city
        +String? gender
        +DateTime? dob
        +bool? isActive
        +DateTime? createdAt
        +DateTime? updatedAt
        +bool hasPremiumAccess
        +AppUser fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
        +AppUser copyWith(...)
    }

    class UserSettings {
        +String id
        +bool pushEnabled
        +bool showOnlineStatus
        +bool showLastSeen
        +bool allowBuddyRequests
        +bool allowGroupInvites
        +String language
        +String themeMode
        +DateTime? updatedAt
        +UserSettings fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    UserSettings --|> FirestoreModel

    class DeviceToken {
        +String id
        +String platform
        +String token
        +DateTime? createdAt
        +DateTime? lastSeenAt
        +DeviceToken fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    DeviceToken --|> FirestoreModel

    %% Social Models
    class BuddyRequest {
        +String id
        +String fromUserId
        +String toUserId
        +BuddyRequestStatus status
        +String message
        +DateTime? createdAt
        +DateTime? respondedAt
        +BuddyRequest fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    BuddyRequest --|> FirestoreModel
    BuddyRequest --> AppUser : fromUserId
    BuddyRequest --> AppUser : toUserId

    class Friendship {
        +String id
        +String userAId
        +String userBId
        +List~String~ userIds
        +DateTime? createdAt
        +bool isBlocked
        +String blockedByUserId
        +Friendship fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Friendship --|> FirestoreModel
    Friendship --> AppUser : userAId
    Friendship --> AppUser : userBId

    class Group {
        +String id
        +String title
        +String photoUrl
        +String description
        +String createdByUserId
        +DateTime? createdAt
        +DateTime? updatedAt
        +int memberCount
        +Group fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Group --|> FirestoreModel
    Group --> AppUser : createdByUserId

    class GroupMember {
        +String id
        +String groupId
        +String userId
        +GroupRole role
        +DateTime? joinedAt
        +bool isMuted
        +DateTime? mutedUntil
        +GroupMember fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    GroupMember --|> FirestoreModel
    GroupMember --> AppUser : userId
    GroupMember --> Group : groupId

    class GroupInvite {
        +String id
        +String groupId
        +String invitedUserId
        +String invitedByUserId
        +GroupInviteStatus status
        +DateTime? createdAt
        +DateTime? respondedAt
        +GroupInvite fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    GroupInvite --|> FirestoreModel
    GroupInvite --> AppUser : invitedUserId
    GroupInvite --> AppUser : invitedByUserId
    GroupInvite --> Group : groupId

    %% Chat Models
    class Conversation {
        +String id
        +ConversationType type
        +String title
        +String groupId
        +String createdByUserId
        +DateTime? createdAt
        +DateTime? updatedAt
        +String lastMessageId
        +String lastMessagePreview
        +DateTime? lastMessageAt
        +Conversation fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Conversation --|> FirestoreModel
    Conversation --> AppUser : createdByUserId
    Conversation --> Group : groupId

    class ConversationParticipant {
        +String id
        +String conversationId
        +String userId
        +DateTime? joinedAt
        +DateTime? lastReadAt
        +bool isMuted
        +DateTime? mutedUntil
        +ConversationParticipant fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    ConversationParticipant --|> FirestoreModel
    ConversationParticipant --> AppUser : userId
    ConversationParticipant --> Conversation : conversationId

    class Message {
        +String id
        +String conversationId
        +String senderUserId
        +MessageType type
        +String text
        +String mediaUrl
        +String thumbnailUrl
        +double? lat
        +double? lng
        +String replyToMessageId
        +DateTime? createdAt
        +bool isDeleted
        +DeliveryState deliveryState
        +Message fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Message --|> FirestoreModel
    Message --> AppUser : senderUserId
    Message --> Conversation : conversationId
    Message --> Message : replyToMessageId

    class MessageReceipt {
        +String id
        +String messageId
        +String userId
        +DeliveryState state
        +DateTime? updatedAt
        +MessageReceipt fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    MessageReceipt --|> FirestoreModel
    MessageReceipt --> Message : messageId
    MessageReceipt --> AppUser : userId

    class UserConversationIndex {
        +String id
        +String conversationId
        +ConversationType type
        +String title
        +String lastMessagePreview
        +DateTime? lastMessageAt
        +int unreadCount
        +UserConversationIndex fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    UserConversationIndex --|> FirestoreModel
    UserConversationIndex --> Conversation : conversationId

    %% Session Models
    class Session {
        +String id
        +SessionType type
        +String title
        +String description
        +String createdByUserId
        +DateTime? startAt
        +DateTime? endAt
        +GeoPoint? location
        +String locationName
        +String gymId
        +SessionStatus status
        +bool isGroupSession
        +String groupId
        +DateTime? createdAt
        +DateTime? updatedAt
        +Session fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Session --|> FirestoreModel
    Session --> AppUser : createdByUserId
    Session --> Gym : gymId
    Session --> Group : groupId

    class SessionParticipant {
        +String id
        +String sessionId
        +String userId
        +bool attended
        +DateTime? joinedAt
        +SessionParticipant fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    SessionParticipant --|> FirestoreModel
    SessionParticipant --> AppUser : userId
    SessionParticipant --> Session : sessionId

    class SessionInvite {
        +String id
        +String sessionId
        +String invitedUserId
        +String invitedByUserId
        +InviteStatus status
        +DateTime? createdAt
        +DateTime? respondedAt
        +String? sessionCategory
        +String? sessionImageUrl
        +String? sessionLocationText
        +DateTime? sessionDateTime
        +String? invitedByName
        +String? invitedByPhotoUrl
        +SessionInvite fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    SessionInvite --|> FirestoreModel
    SessionInvite --> AppUser : invitedUserId
    SessionInvite --> AppUser : invitedByUserId
    SessionInvite --> Session : sessionId

    %% Gym Models
    class Gym {
        +String id
        +String name
        +String address
        +GeoPoint? location
        +String city
        +String phone
        +String logoUrl
        +GymStatus status
        +String qrPublicId
        +DateTime? createdAt
        +DateTime? updatedAt
        +int yearsOfService
        +int members
        +double rating
        +String dayHours
        +String nightHours
        +List~String~ equipments
        +List~String~ images
        +int monthlyScans
        +int totalScans
        +Gym fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Gym --|> FirestoreModel

    class GymScan {
        +String id
        +String userId
        +String gymId
        +String subscriptionId
        +DateTime? scannedAt
        +ScanResult result
        +String deviceId
        +GeoPoint? scanLocation
        +String notes
        +GymScan fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    GymScan --|> FirestoreModel
    GymScan --> AppUser : userId
    GymScan --> Gym : gymId
    GymScan --> Subscription : subscriptionId

    %% Subscription Models
    class Plan {
        +String id
        +String name
        +String description
        +double price
        +String currency
        +int durationDays
        +List~String~ features
        +bool isActive
        +DateTime? createdAt
        +DateTime? updatedAt
        +Plan fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Plan --|> FirestoreModel

    class Subscription {
        +String id
        +String userId
        +String planId
        +SubscriptionStatus status
        +String provider
        +String providerSubId
        +DateTime? startAt
        +DateTime? currentPeriodEnd
        +DateTime? cancelledAt
        +DateTime? createdAt
        +DateTime? updatedAt
        +Subscription fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    Subscription --|> FirestoreModel
    Subscription --> AppUser : userId
    Subscription --> Plan : planId

    class PaymentTransaction {
        +String id
        +String userId
        +String subscriptionId
        +double amount
        +String currency
        +String provider
        +String providerTxnId
        +String status
        +DateTime? createdAt
        +PaymentTransaction fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    PaymentTransaction --|> FirestoreModel
    PaymentTransaction --> AppUser : userId
    PaymentTransaction --> Subscription : subscriptionId

    %% Other Models
    class Activity {
        +String id
        +String name
        +int order
        +bool isActive
        +DateTime? createdAt
        +DateTime? updatedAt
        +Activity fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
        +Activity copyWith(...)
    }

    class AppNotification {
        +String id
        +String userId
        +NotificationType type
        +String title
        +String body
        +Map~String,dynamic~ data
        +bool isRead
        +DateTime? createdAt
        +AppNotification fromDoc(DocumentSnapshot doc)
        +Map~String,dynamic~ toMap()
    }
    AppNotification --|> FirestoreModel
    AppNotification --> AppUser : userId

    class Product {
        +String id
        +String title
        +String description
        +double price
        +String imageUrl
        +bool isActive
        +DateTime? createdAt
        +Product fromDoc(DocumentSnapshot doc)
    }

    %% Repositories
    class RepoBase {
        #FirebaseFirestore db
        +RepoBase(FirebaseFirestore db)
        +CollectionReference col(String path)
        +DocumentReference doc(String path)
        +Query applyPaging(Query q, DocumentSnapshot? startAfter, int limit)
    }

    class Repos {
        +FirebaseFirestore db
        +FirebaseAuth auth
        +FirebaseStorage storage
        +FirebaseFunctions functions
        +ActivityRepo activityRepo
        +AuthRepo authRepo
        +BuddyRepo buddyRepo
        +GroupRepo groupRepo
        +ChatRepo chatRepo
        +SessionRepo sessionRepo
        +GymRepo gymRepo
        +ScanRepo scanRepo
        +NotificationRepo notificationRepo
        +MediaRepo mediaRepo
        +Repos(...)
    }

    class AuthRepo {
        #FirebaseAuth auth
        +AuthRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~User?~ authState()
        +String requireUid()
        +Future~void~ signOut()
        +Stream~AppUser?~ watchMe()
        +Future~AppUser~ getUser(String uid)
        +Future~void~ upsertMe(AppUser user, bool merge)
        +Future~void~ updateMeFields(Map~String,dynamic~ fields)
        +Stream~UserSettings?~ watchMySettings()
        +Future~void~ upsertMySettings(UserSettings settings)
        +Future~AppUser?~ getMeOnce()
        +Future~String~ uploadMyProfileImage(File file)
    }
    AuthRepo --|> RepoBase
    AuthRepo ..> AppUser : manages
    AuthRepo ..> UserSettings : manages

    class BuddyRepo {
        #FirebaseAuth auth
        +BuddyRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~BuddyRequest~~ watchIncomingRequests()
        +Stream~List~BuddyRequest~~ watchOutgoingRequests()
        +Future~String~ sendBuddyRequest(String toUserId, String message)
        +Future~void~ cancelBuddyRequest(String requestId)
        +Future~void~ declineBuddyRequest(String requestId)
        +Future~void~ acceptBuddyRequest(String requestId)
        +Stream~List~Friendship~~ watchMyFriendships(int limit)
        +Stream~List~AppUser~~ watchMyBuddiesUsers(int limit)
        +Future~List~AppUser~~ loadDiscoverUsers(int limit, String? activity, String? city)
        +Future~Map~String,AppUser~~ loadUsersMapByIds(List~String~ ids)
        +Future~List~AppUser~~ loadAnyBuddies(int limit)
    }
    BuddyRepo --|> RepoBase
    BuddyRepo ..> BuddyRequest : manages
    BuddyRepo ..> Friendship : manages
    BuddyRepo ..> AppUser : manages

    class GroupRepo {
        #FirebaseAuth auth
        +GroupRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~Group~~ watchMyGroupsByMembership()
        +Future~String~ createGroup(String title, String description, String photoUrl, List~String~ initialMemberUserIds)
        +Stream~List~GroupMember~~ watchGroupMembers(String groupId)
        +Future~String~ inviteToGroup(String groupId, String invitedUserId)
        +Stream~List~GroupInvite~~ watchMyGroupInvites()
        +Future~void~ acceptGroupInvite(String groupId, String inviteId)
        +Future~void~ declineGroupInvite(String groupId, String inviteId)
    }
    GroupRepo --|> RepoBase
    GroupRepo ..> Group : manages
    GroupRepo ..> GroupMember : manages
    GroupRepo ..> GroupInvite : manages
    GroupRepo ..> Conversation : manages
    GroupRepo ..> ConversationParticipant : manages

    class ChatRepo {
        #FirebaseAuth auth
        +ChatRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~(UserConversationIndex,Conversation?)~~ watchMyInbox(int limit)
        +Stream~List~ConversationParticipant~~ watchParticipants(String conversationId)
        +Future~String~ getOrCreateDirectConversation(String otherUserId)
        +Future~String~ createGroupConversation(String title, List~String~ memberUserIds)
        +Stream~List~Message~~ watchMessages(String conversationId, int limit)
        +Future~String~ sendMessage(String conversationId, MessageType type, String text, ...)
        +Future~void~ markConversationRead(String conversationId)
        +Future~void~ leaveConversation(String conversationId)
    }
    ChatRepo --|> RepoBase
    ChatRepo ..> Conversation : manages
    ChatRepo ..> ConversationParticipant : manages
    ChatRepo ..> Message : manages
    ChatRepo ..> UserConversationIndex : manages

    class SessionRepo {
        #FirebaseAuth auth
        +SessionRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~Session~~ watchMySessions(int limit)
        +Future~String~ createSession(Session session)
        +Future~String~ inviteUserToSession(String sessionId, String invitedUserId)
        +Stream~List~SessionInvite~~ watchMySessionInvites(int limit)
        +Future~void~ acceptSessionInvite(String sessionId, String inviteId)
        +Future~void~ declineSessionInvite(String sessionId, String inviteId)
        +Stream~List~SessionParticipant~~ watchParticipants(String sessionId)
    }
    SessionRepo --|> RepoBase
    SessionRepo ..> Session : manages
    SessionRepo ..> SessionInvite : manages
    SessionRepo ..> SessionParticipant : manages

    class GymRepo {
        #FirebaseAuth auth
        +GymRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~Gym~~ watchGyms(String city, int limit)
        +Future~Gym~ getGym(String gymId)
        +Stream~List~Plan~~ watchActivePlans()
        +Stream~List~Subscription~~ watchMySubscriptions(int limit)
        +Stream~Subscription?~ watchMyActiveSubscription()
        +Future~Subscription?~ getMyActiveSubscriptionOnce()
        +Stream~List~PaymentTransaction~~ watchMyTransactions(int limit)
    }
    GymRepo --|> RepoBase
    GymRepo ..> Gym : manages
    GymRepo ..> Plan : manages
    GymRepo ..> Subscription : manages
    GymRepo ..> PaymentTransaction : manages

    class ScanRepo {
        #FirebaseAuth auth
        #FirebaseFunctions functions
        +ScanRepo(FirebaseFirestore db, FirebaseAuth auth, FirebaseFunctions functions)
        +Stream~List~GymScan~~ watchMyScanHistory(int limit)
        +Future~Map~String,dynamic~~ validateAndCreateScan(String qrPayload, GeoPoint? scanLocation, String deviceId)
        +Future~String~ createScanClientWrite(String gymId, ScanResult result, ...)
    }
    ScanRepo --|> RepoBase
    ScanRepo ..> GymScan : manages

    class ActivityRepo {
        #FirebaseAuth auth
        +ActivityRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~Activity~~ watchActiveActivities()
        +Future~void~ createActivity(Activity activity)
        +Future~void~ updateActivity(String id, Map~String,dynamic~ fields)
        +Future~void~ deactivateActivity(String id)
    }
    ActivityRepo --|> RepoBase
    ActivityRepo ..> Activity : manages

    class NotificationRepo {
        #FirebaseAuth auth
        +NotificationRepo(FirebaseFirestore db, FirebaseAuth auth)
        +Stream~List~AppNotification~~ watchMyNotifications(int limit)
        +Future~void~ markRead(String notificationId)
        +Future~void~ markAllRead()
    }
    NotificationRepo --|> RepoBase
    NotificationRepo ..> AppNotification : manages

    class MediaRepo {
        #FirebaseStorage storage
        #FirebaseAuth auth
        +MediaRepo(FirebaseStorage storage, FirebaseAuth auth)
        +Future~String~ uploadProfilePhoto(File file)
        +Future~String~ uploadChatMedia(String conversationId, File file, String ext)
    }
    MediaRepo ..> AppUser : supports
    MediaRepo ..> Conversation : supports
```

## Legend

- `--|>` : Inheritance (implements/extends)
- `-->` : Association (references)
- `..>` : Dependency (manages/uses)

## Notes

- Most models implement `FirestoreModel` for Firestore serialization
- `AppUser` is central to most relationships
- Repositories follow the Repository pattern with `RepoBase` as base class
- `Repos` class provides centralized access to all repositories

