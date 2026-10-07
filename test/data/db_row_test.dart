import 'package:fitbud/data/doc.dart';
import 'package:fitbud/domain/models/common/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DbRow', () {
    test('snake <-> camel conversion', () {
      expect(DbRow.camel('last_message_at'), 'lastMessageAt');
      expect(DbRow.camel('id'), 'id');
      expect(DbRow.snake('lastMessageAt'), 'last_message_at');
    });

    test('toCamel maps every top-level key', () {
      final m = DbRow.toCamel({'user_id': 'u1', 'is_read': true});
      expect(m, {'userId': 'u1', 'isRead': true});
    });

    test('toRow snake-cases keys, encodes values and drops id/excluded keys', () {
      final row = DbRow.toRow({
        'id': 'x',
        'createdAt': DateTime.utc(2026, 1, 2, 3, 4, 5),
        'location': const GeoPoint(31.5, 74.3),
        'isPremium': true,
        'displayName': 'A',
      }, drop: {'isPremium'});
      expect(row, {
        'created_at': '2026-01-02T03:04:05.000Z',
        'location': {'lat': 31.5, 'lng': 74.3},
        'display_name': 'A',
      });
    });

    test('Doc.fromRow uses the requested id column', () {
      final d = Doc.fromRow({'user_id': 'u9', 'unread_count': 3}, idKey: 'user_id');
      expect(d.id, 'u9');
      expect(d.data()['unreadCount'], 3);
    });
  });
}
