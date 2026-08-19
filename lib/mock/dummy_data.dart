// lib/mock/dummy_data.dart
//
// Seeds a FakeFirebaseFirestore with enough realistic-looking data (with
// hosted placeholder images) for every major screen to render nicely without
// touching the real backend. Used only by lib/main_mock.dart.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/activities/activity.dart';
import '../domain/models/auth/app_user.dart';
import '../domain/models/auth/user_address.dart';
import '../domain/models/auth/user_settings.dart';
import '../domain/models/buddies/buddy_request.dart';
import '../domain/models/buddies/friendship.dart';
import '../domain/models/chat/conversation.dart';
import '../domain/models/chat/conversation_participant.dart';
import '../domain/models/chat/message.dart';
import '../domain/models/chat/user_conversation_index.dart';
import '../domain/models/groups/group.dart';
import '../domain/models/groups/group_member.dart';
import '../domain/models/gyms/gym.dart';
import '../domain/models/gyms/gym_scan.dart';
import '../domain/models/notifications/app_notification.dart';
import '../domain/models/plans/plan.dart';
import '../domain/models/sessions/session.dart';
import '../domain/models/sessions/session_invite.dart';
import '../domain/models/subscription/payment_transaction.dart';
import '../domain/models/subscription/subscription.dart';
import '../domain/repos/firestore_paths.dart';

// DiceBear serves CORS-enabled PNGs, so this renders on web too (unlike
// i.pravatar.cc, which doesn't send Access-Control-Allow-Origin and fails
// to load under Flutter Web).
String _avatar(int seed) =>
    'https://api.dicebear.com/7.x/avataaars/png?seed=buddy$seed&size=300';
String _photo(String seed, {int w = 600, int h = 400}) =>
    'https://picsum.photos/seed/$seed/$w/$h';

class DummyBuddy {
  final String uid;
  final String name;
  final int avatar;
  final String city;
  final List<String> activities;
  final bool premium;
  const DummyBuddy(this.uid, this.name, this.avatar, this.city, this.activities, this.premium);
}

const _buddies = <DummyBuddy>[
  DummyBuddy('buddy_ali', 'Ali Haider', 12, 'Lahore', ['Gym', 'Cricket'], true),
  DummyBuddy('buddy_fatima', 'Fatima Noor', 47, 'Karachi', ['Yoga', 'Running'], true),
  DummyBuddy('buddy_sufyan', 'Sufyan Raza', 33, 'Islamabad', ['Football', 'Gym'], false),
  DummyBuddy('buddy_hina', 'Hina Malik', 25, 'Lahore', ['Cycling', 'Swimming'], true),
  DummyBuddy('buddy_usman', 'Usman Tariq', 8, 'Faisalabad', ['Boxing', 'Gym'], false),
  DummyBuddy('buddy_ayesha', 'Ayesha Khan', 44, 'Karachi', ['Tennis', 'Running'], true),
  DummyBuddy('buddy_bilal', 'Bilal Ahmed', 15, 'Lahore', ['Gym', 'Swimming'], false),
  DummyBuddy('buddy_zara', 'Zara Sheikh', 29, 'Multan', ['Yoga', 'Cycling'], true),
];

const _activityDefs = <List<String>>[
  ['Gym', 'gym'],
  ['Running', 'running'],
  ['Cycling', 'cycling'],
  ['Yoga', 'yoga'],
  ['Cricket', 'cricket'],
  ['Football', 'football'],
  ['Swimming', 'swimming'],
  ['Tennis', 'tennis'],
  ['Boxing', 'boxing'],
];

const _gymDefs = <List<String>>[
  ['Iron Paradise Gym', 'Gulberg III', 'Lahore', '042-111222333'],
  ['FitZone Fitness Club', 'DHA Phase 5', 'Karachi', '021-111222444'],
  ['PowerHouse Gym', 'F-7 Markaz', 'Islamabad', '051-111222555'],
  ['Elite Fitness Studio', 'Model Town', 'Lahore', '042-111222666'],
  ['Champions Gym', 'Clifton', 'Karachi', '021-111222777'],
  ['Peak Performance Gym', 'G-9', 'Islamabad', '051-111222888'],
];

Future<void> seedDummyData(
  FirebaseFirestore db, {
  required String meUid,
  required String meName,
  required String meEmail,
}) async {
  final now = DateTime.now();
  final batch1 = db.batch();

  // ---------------- Me ----------------
  final me = AppUser(
    id: meUid,
    displayName: meName,
    email: meEmail,
    phone: '+92 300 1234567',
    photoUrl: _avatar(68),
    isPremium: true,
    premiumUntil: now.add(const Duration(days: 45)),
    activePlanId: 'plan_pro',
    activeSubscriptionId: 'sub_me',
    activities: const ['Gym', 'Running', 'Cricket'],
    favouriteActivity: 'Gym',
    hasGym: true,
    gymName: _gymDefs[0][0],
    about: 'Fitness enthusiast. Always up for a morning run or a gym session 💪',
    isProfileComplete: true,
    city: 'Lahore',
    gender: 'Male',
    dob: DateTime(1998, 4, 12),
    isActive: true,
    createdAt: now.subtract(const Duration(days: 120)),
    updatedAt: now,
  );
  batch1.set(db.doc('${FirestorePaths.users}/$meUid'), me.toMap());

  batch1.set(
    db.doc(FirestorePaths.userSettings(meUid)),
    UserSettings(id: 'settings', selectedAddressId: 'addr_home', updatedAt: now).toMap(),
  );

  batch1.set(
    db.doc('${FirestorePaths.userAddresses(meUid)}/addr_home'),
    UserAddress(
      id: 'addr_home',
      label: 'Home',
      city: 'Lahore',
      line1: 'House 12, Street 4, Gulberg III',
      line2: 'Near Liberty Market',
      lat: 31.5204,
      lng: 74.3587,
      isDefault: true,
      createdAt: now.subtract(const Duration(days: 100)),
      updatedAt: now.subtract(const Duration(days: 100)),
    ).toMap(),
  );

  // ---------------- Buddy users ----------------
  for (final b in _buddies) {
    batch1.set(
      db.doc('${FirestorePaths.users}/${b.uid}'),
      AppUser(
        id: b.uid,
        displayName: b.name,
        email: '${b.uid}@fitbud.demo',
        phone: '+92 3${(b.avatar).toString().padLeft(2, '0')} 0000000',
        photoUrl: _avatar(b.avatar),
        isPremium: b.premium,
        activities: b.activities,
        favouriteActivity: b.activities.first,
        hasGym: true,
        gymName: _gymDefs[b.avatar % _gymDefs.length][0],
        about: 'Training buddy from ${b.city}. Let\'s work out together!',
        isProfileComplete: true,
        city: b.city,
        gender: b.avatar.isEven ? 'Male' : 'Female',
        isActive: true,
        createdAt: now.subtract(Duration(days: 60 + b.avatar)),
        updatedAt: now,
      ).toMap(),
    );
  }
  await batch1.commit();

  // ---------------- Activities (categories) ----------------
  final batch2 = db.batch();
  for (var i = 0; i < _activityDefs.length; i++) {
    final name = _activityDefs[i][0];
    final slug = _activityDefs[i][1];
    batch2.set(
      db.collection(FirestorePaths.activities).doc('act_$slug'),
      Activity(
        id: 'act_$slug',
        name: name,
        order: i,
        isActive: true,
        iconUrl: _photo('activity-$slug', w: 200, h: 200),
        imageUrl: _photo('activity-$slug-banner', w: 500, h: 300),
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ).toMap(),
    );
  }

  // ---------------- Gyms ----------------
  for (var i = 0; i < _gymDefs.length; i++) {
    final g = _gymDefs[i];
    batch2.set(
      db.collection(FirestorePaths.gyms).doc('gym_$i'),
      Gym(
        id: 'gym_$i',
        name: g[0],
        address: g[1],
        city: g[2],
        phone: g[3],
        logoUrl: _photo('gym-$i-logo', w: 300, h: 300),
        status: GymStatus.active,
        qrPublicId: 'QR-GYM-$i',
        createdAt: now.subtract(Duration(days: 300 - i * 10)),
        updatedAt: now,
        yearsOfService: 3 + i,
        members: 220 + i * 37,
        rating: 4.2 + (i % 3) * 0.2,
        dayHours: '6:00 AM - 10:00 PM',
        nightHours: '10:00 PM - 6:00 AM (Ladies only)',
        equipments: const ['Treadmills', 'Free Weights', 'Cable Machines', 'Squat Racks', 'Cardio Zone'],
        images: [
          _photo('gym-$i-1', w: 700, h: 450),
          _photo('gym-$i-2', w: 700, h: 450),
          _photo('gym-$i-3', w: 700, h: 450),
        ],
        monthlyScans: 340 + i * 21,
        totalScans: 5200 + i * 300,
      ).toMap(),
    );
  }

  // ---------------- Plans ----------------
  final planDefs = [
    ('plan_basic', 'Basic', 'Great for getting started', 1999.0, 30, ['Access to all partner gyms', 'Standard support']),
    ('plan_pro', 'Pro', 'Most popular — full flexibility', 4999.0, 30, ['Access to all partner gyms', 'Priority support', 'Buddy matching', 'Group sessions']),
    ('plan_elite', 'Elite', 'Best value for serious athletes', 49999.0, 365, ['Everything in Pro', '2 free personal training sessions/month', 'Premium badge', 'Early access to events']),
  ];
  for (var i = 0; i < planDefs.length; i++) {
    final p = planDefs[i];
    batch2.set(
      db.collection(FirestorePaths.plans).doc(p.$1),
      Plan(
        id: p.$1,
        name: p.$2,
        description: p.$3,
        price: p.$4,
        currency: 'PKR',
        durationDays: p.$5,
        features: p.$6,
        isActive: true,
        createdAt: now.subtract(Duration(days: 300 - i)),
        updatedAt: now,
      ).toMap(),
    );
  }

  // ---------------- Subscription + transactions (me) ----------------
  batch2.set(
    db.collection(FirestorePaths.subscriptions).doc('sub_me'),
    Subscription(
      id: 'sub_me',
      userId: meUid,
      planId: 'plan_pro',
      status: SubscriptionStatus.active,
      provider: 'JazzCash',
      providerSubId: 'JC-DEMO-001',
      startAt: now.subtract(const Duration(days: 15)),
      currentPeriodEnd: now.add(const Duration(days: 15)),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now,
    ).toMap(),
  );

  for (var i = 0; i < 3; i++) {
    batch2.set(
      db.collection(FirestorePaths.transactions).doc('txn_$i'),
      PaymentTransaction(
        id: 'txn_$i',
        userId: meUid,
        subscriptionId: 'sub_me',
        amount: 4999,
        currency: 'PKR',
        provider: i == 0 ? 'JazzCash' : 'EasyPaisa',
        providerTxnId: 'TXN-DEMO-00$i',
        status: 'succeeded',
        createdAt: now.subtract(Duration(days: 15 + i * 30)),
      ).toMap(),
    );
  }

  // ---------------- Gym scans (me) ----------------
  for (var i = 0; i < 6; i++) {
    final gymIdx = i % _gymDefs.length;
    batch2.set(
      db.collection(FirestorePaths.scans).doc('scan_$i'),
      GymScan(
        id: 'scan_$i',
        userId: meUid,
        gymId: 'gym_$gymIdx',
        subscriptionId: 'sub_me',
        scannedAt: now.subtract(Duration(days: i * 2, hours: 3)),
        result: ScanResult.allowed,
        deviceId: 'demo-device',
      ).toMap(),
    );
  }
  await batch2.commit();

  // ---------------- Friendships (me <-> 4 buddies) ----------------
  final batch3 = db.batch();
  final buddyFriendIds = _buddies.take(4).map((b) => b.uid).toList();
  for (final otherId in buddyFriendIds) {
    final ids = [meUid, otherId]..sort();
    batch3.set(
      db.collection(FirestorePaths.friendships).doc('${ids[0]}_${ids[1]}'),
      Friendship(
        id: '${ids[0]}_${ids[1]}',
        userAId: ids[0],
        userBId: ids[1],
        userIds: ids,
        createdAt: now.subtract(const Duration(days: 20)),
      ).toMap(),
    );
  }

  // ---------------- Buddy requests ----------------
  // Incoming pending (from buddies[4], buddies[5])
  batch3.set(
    db.collection(FirestorePaths.buddyRequests).doc('req_in_1'),
    BuddyRequest(
      id: 'req_in_1',
      fromUserId: _buddies[4].uid,
      toUserId: meUid,
      status: BuddyRequestStatus.pending,
      message: 'Hey! Want to be gym buddies?',
      createdAt: now.subtract(const Duration(hours: 5)),
    ).toMap(),
  );
  batch3.set(
    db.collection(FirestorePaths.buddyRequests).doc('req_in_2'),
    BuddyRequest(
      id: 'req_in_2',
      fromUserId: _buddies[5].uid,
      toUserId: meUid,
      status: BuddyRequestStatus.pending,
      message: 'Saw you also play tennis, let\'s train together!',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    ).toMap(),
  );
  // Outgoing pending (to buddies[6])
  batch3.set(
    db.collection(FirestorePaths.buddyRequests).doc('req_out_1'),
    BuddyRequest(
      id: 'req_out_1',
      fromUserId: meUid,
      toUserId: _buddies[6].uid,
      status: BuddyRequestStatus.pending,
      message: 'Hi, let\'s be workout buddies!',
      createdAt: now.subtract(const Duration(hours: 10)),
    ).toMap(),
  );
  await batch3.commit();

  // ---------------- Conversations + messages + inbox ----------------
  final chatPartners = _buddies.take(3).toList();
  final chatLines = [
    ['Hey! Are we still on for gym today?', 'Yeah man, 6pm as usual 💪', 'Perfect, see you there!'],
    ['Congrats on hitting your PR!', 'Thank you! Couldn\'t have done it without our sessions', 'Let\'s keep pushing 🔥'],
    ['Did you check out the new gym downtown?', 'Not yet, is it good?', 'Amazing equipment, we should try it this weekend'],
  ];

  for (var i = 0; i < chatPartners.length; i++) {
    final other = chatPartners[i];
    final ids = [meUid, other.uid]..sort();
    final convId = 'direct_${ids[0]}_${ids[1]}';
    final lines = chatLines[i % chatLines.length];
    final convBatch = db.batch();

    convBatch.set(
      db.doc('${FirestorePaths.conversations}/$convId'),
      Conversation(
        id: convId,
        type: ConversationType.direct,
        createdByUserId: meUid,
        createdAt: now.subtract(Duration(days: 5 - i)),
        updatedAt: now.subtract(Duration(hours: i)),
        lastMessagePreview: lines.last,
        lastMessageAt: now.subtract(Duration(hours: i)),
      ).toMap(),
    );

    convBatch.set(
      db.doc('${FirestorePaths.conversationParticipants(convId)}/$meUid'),
      ConversationParticipant(
        id: meUid,
        conversationId: convId,
        userId: meUid,
        joinedAt: now.subtract(Duration(days: 5 - i)),
        lastReadAt: now.subtract(Duration(hours: i)),
      ).toMap(),
    );
    convBatch.set(
      db.doc('${FirestorePaths.conversationParticipants(convId)}/${other.uid}'),
      ConversationParticipant(
        id: other.uid,
        conversationId: convId,
        userId: other.uid,
        joinedAt: now.subtract(Duration(days: 5 - i)),
      ).toMap(),
    );

    for (var m = 0; m < lines.length; m++) {
      final fromMe = m.isOdd; // alternate sender, last line from buddy
      convBatch.set(
        db.doc('${FirestorePaths.conversationMessages(convId)}/msg_${convId}_$m'),
        Message(
          id: 'msg_${convId}_$m',
          conversationId: convId,
          senderUserId: fromMe ? meUid : other.uid,
          type: MessageType.text,
          text: lines[m],
          createdAt: now.subtract(Duration(hours: i, minutes: (lines.length - m) * 5)),
          deliveryState: DeliveryState.read,
        ).toMap(),
      );
    }

    convBatch.set(
      db.doc('${FirestorePaths.userConversations(meUid)}/$convId'),
      UserConversationIndex(
        id: convId,
        conversationId: convId,
        type: ConversationType.direct,
        title: other.name,
        lastMessagePreview: lines.last,
        lastMessageAt: now.subtract(Duration(hours: i)),
        unreadCount: i == 0 ? 2 : 0,
      ).toMap(),
    );
    convBatch.set(
      db.doc('${FirestorePaths.userConversations(other.uid)}/$convId'),
      UserConversationIndex(
        id: convId,
        conversationId: convId,
        type: ConversationType.direct,
        title: meName,
        lastMessagePreview: lines.last,
        lastMessageAt: now.subtract(Duration(hours: i)),
        unreadCount: 0,
      ).toMap(),
    );

    await convBatch.commit();
  }

  // ---------------- Notifications ----------------
  // Seeded in two places: the per-user subcollection NotificationRepo reads,
  // and the root "notifications" collection NotificationsScreen queries directly.
  final notifDefs = [
    (NotificationType.buddy_request, 'New Buddy Request', '${_buddies[4].name} wants to be your gym buddy', false),
    (NotificationType.message, 'New Message', '${_buddies[0].name} sent you a message', false),
    (NotificationType.buddy_accepted, 'Buddy Request Accepted', '${_buddies[1].name} accepted your request', true),
    (NotificationType.session_invite, 'Session Invite', 'You\'ve been invited to a group workout', false),
    (NotificationType.subscription, 'Subscription Renewed', 'Your Pro plan was renewed successfully', true),
  ];
  final batch4 = db.batch();
  for (var i = 0; i < notifDefs.length; i++) {
    final n = notifDefs[i];
    final map = AppNotification(
      id: 'notif_$i',
      userId: meUid,
      type: n.$1,
      title: n.$2,
      body: n.$3,
      isRead: n.$4,
      createdAt: now.subtract(Duration(hours: i * 4)),
    ).toMap();
    batch4.set(db.doc('${FirestorePaths.userNotifications(meUid)}/notif_$i'), map);
    batch4.set(db.collection(FirestorePaths.notifications).doc('notif_$i'), map);
  }

  // ---------------- Groups ----------------
  batch4.set(
    db.collection(FirestorePaths.groups).doc('group_1'),
    Group(
      id: 'group_1',
      title: 'Lahore Morning Runners',
      photoUrl: _photo('group-runners', w: 400, h: 400),
      description: 'Early morning running crew around Gulberg & Model Town',
      createdByUserId: meUid,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      memberCount: 3,
    ).toMap(),
  );
  batch4.set(
    db.doc('${FirestorePaths.groupMembers('group_1')}/$meUid'),
    GroupMember(id: meUid, groupId: 'group_1', userId: meUid, role: GroupRole.owner, joinedAt: now.subtract(const Duration(days: 30))).toMap(),
  );
  batch4.set(
    db.doc('${FirestorePaths.groupMembers('group_1')}/${_buddies[0].uid}'),
    GroupMember(id: _buddies[0].uid, groupId: 'group_1', userId: _buddies[0].uid, role: GroupRole.member, joinedAt: now.subtract(const Duration(days: 25))).toMap(),
  );
  batch4.set(
    db.doc('${FirestorePaths.groupMembers('group_1')}/${_buddies[1].uid}'),
    GroupMember(id: _buddies[1].uid, groupId: 'group_1', userId: _buddies[1].uid, role: GroupRole.member, joinedAt: now.subtract(const Duration(days: 20))).toMap(),
  );

  // ---------------- Products (Home banners) ----------------
  final productDefs = [
    ('Whey Protein 2kg', 'Premium whey protein — chocolate flavor', 8999.0),
    ('Resistance Bands Set', '5-piece resistance band set for home workouts', 1499.0),
    ('Shaker Bottle', 'Leak-proof 700ml shaker bottle', 599.0),
    ('Gym Gloves', 'Breathable weightlifting gloves', 1299.0),
  ];
  for (var i = 0; i < productDefs.length; i++) {
    final p = productDefs[i];
    batch4.set(
      db.collection('products').doc('prod_$i'),
      {
        'title': p.$1,
        'description': p.$2,
        'price': p.$3,
        'imageUrl': _photo('product-$i', w: 500, h: 500),
        'isActive': true,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i))),
      },
    );
  }

  // ---------------- Session + invite (Home invites) ----------------
  batch4.set(
    db.collection(FirestorePaths.sessions).doc('session_1'),
    Session(
      id: 'session_1',
      type: SessionType.gym,
      title: 'Saturday Group Workout',
      description: 'Full body group session at Iron Paradise Gym',
      createdByUserId: _buddies[0].uid,
      startAt: now.add(const Duration(days: 2, hours: 9)),
      endAt: now.add(const Duration(days: 2, hours: 11)),
      locationName: _gymDefs[0][0],
      gymId: 'gym_0',
      status: SessionStatus.scheduled,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    ).toMap(),
  );
  batch4.set(
    db.doc('${FirestorePaths.sessionInvites('session_1')}/invite_1'),
    SessionInvite(
      id: 'invite_1',
      sessionId: 'session_1',
      invitedUserId: meUid,
      invitedByUserId: _buddies[0].uid,
      status: InviteStatus.pending,
      createdAt: now.subtract(const Duration(hours: 6)),
      sessionCategory: 'Gym',
      sessionImageUrl: _photo('gym-0-1', w: 700, h: 450),
      sessionLocationText: _gymDefs[0][0],
      sessionDateTime: now.add(const Duration(days: 2, hours: 9)),
      invitedByName: _buddies[0].name,
      invitedByPhotoUrl: _avatar(_buddies[0].avatar),
    ).toMap(),
  );

  await batch4.commit();
}
