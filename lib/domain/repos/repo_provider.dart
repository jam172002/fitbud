import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_instances.dart';
import 'account/account_repo.dart';
import 'activities/activity_repo.dart';
import 'auth/auth_repo.dart';
import 'buddies/buddy_repo.dart';
import 'chat/chat_repo.dart';
import 'groups/group_repo.dart';
import 'gyms/gym_repo.dart';
import 'media/media_repo.dart';
import 'moderation/moderation_repo.dart';
import 'notifications/notification_repo.dart';
import 'scans/scan_repo.dart';
import 'sessions/session_repo.dart';

class Repos {
  final SupabaseClient db;
  late final ActivityRepo activityRepo = ActivityRepo(db);
  late final AuthRepo authRepo = AuthRepo(db);
  late final BuddyRepo buddyRepo = BuddyRepo(db);
  late final GroupRepo groupRepo = GroupRepo(db);
  late final ChatRepo chatRepo = ChatRepo(db);
  late final SessionRepo sessionRepo = SessionRepo(db);
  late final GymRepo gymRepo = GymRepo(db);
  late final ScanRepo scanRepo = ScanRepo(db);
  late final NotificationRepo notificationRepo = NotificationRepo(db);
  late final MediaRepo mediaRepo = MediaRepo(db);
  late final ModerationRepo moderationRepo = ModerationRepo(db);
  late final AccountRepo accountRepo = AccountRepo(db);

  Repos({SupabaseClient? client}) : db = client ?? SupabaseInstances.client;
}
