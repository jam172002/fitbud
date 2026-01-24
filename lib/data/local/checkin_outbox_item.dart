import 'package:hive/hive.dart';

part 'checkin_outbox_item.g.dart';

@HiveType(typeId: 51)
class CheckinOutboxItem extends HiveObject {
  @HiveField(0)
  final String clientCheckinId;

  @HiveField(1)
  final String gymId;

  @HiveField(2)
  final int createdAtMs;

  @HiveField(3)
  String status; // pending | sending | confirmed | failed

  @HiveField(4)
  int attempts;

  @HiveField(5)
  String lastError;

  CheckinOutboxItem({
    required this.clientCheckinId,
    required this.gymId,
    required this.createdAtMs,
    this.status = 'pending',
    this.attempts = 0,
    this.lastError = '',
  });
}
