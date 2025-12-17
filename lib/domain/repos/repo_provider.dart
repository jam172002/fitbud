import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth/auth_repo.dart';
import 'buddies/buddy_repo.dart';
import 'groups/group_repo.dart';
import 'chat/chat_repo.dart';
import 'sessions/session_repo.dart';
import 'gyms/gym_repo.dart';
import 'scans/scan_repo.dart';
import 'notifications/notification_repo.dart';
import 'media/media_repo.dart';

class Repos {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final FirebaseStorage storage;
  final FirebaseFunctions functions;

  late final AuthRepo authRepo = AuthRepo(db, auth);
  late final BuddyRepo buddyRepo = BuddyRepo(db, auth);
  late final GroupRepo groupRepo = GroupRepo(db, auth);
  late final ChatRepo chatRepo = ChatRepo(db, auth);
  late final SessionRepo sessionRepo = SessionRepo(db, auth);
  late final GymRepo gymRepo = GymRepo(db, auth);
  late final ScanRepo scanRepo = ScanRepo(db, auth, functions);
  late final NotificationRepo notificationRepo = NotificationRepo(db, auth);
  late final MediaRepo mediaRepo = MediaRepo(storage, auth);

  Repos({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  })  : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance,
        storage = storage ?? FirebaseStorage.instance,
        functions = functions ?? FirebaseFunctions.instance;
}
