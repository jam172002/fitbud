import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeed {
  static final _db = FirebaseFirestore.instance;

  /// Run this ONCE only
  static Future<void> seedAll() async {
    await _seedActivities();
    await _seedGyms();
  }

  // -------------------------
  // Activities
  // -------------------------
  static Future<void> _seedActivities() async {
    final activities = [
      {'id': 'badminton', 'name': 'Badminton', 'order': 1},
      {'id': 'gym', 'name': 'Gym', 'order': 2},
      {'id': 'running', 'name': 'Running', 'order': 3},
      {'id': 'football', 'name': 'Football', 'order': 4},
      {'id': 'cricket', 'name': 'Cricket', 'order': 5},
      {'id': 'yoga', 'name': 'Yoga', 'order': 6},
      {'id': 'cycling', 'name': 'Cycling', 'order': 7},
    ];

    for (final a in activities) {
      final ref = _db.collection('activities').doc(a['id'] as String);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          'name': a['name'],
          'order': a['order'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // -------------------------
  // Gyms
  // -------------------------
  static Future<void> _seedGyms() async {
    final gyms = [
      {
        'id': '360_gym_lahore',
        'name': '360 GYM Commercial Area',
        'city': 'Lahore',
      },
      {
        'id': 'iron_house_fitness',
        'name': 'Iron House Fitness',
        'city': 'Lahore',
      },
      {
        'id': 'gold_gym_dha',
        'name': 'Gold Gym DHA',
        'city': 'Lahore',
      },
      {
        'id': 'fitness_hub_model_town',
        'name': 'Fitness Hub Model Town',
        'city': 'Lahore',
      },
      {
        'id': 'powerhouse_gym',
        'name': 'PowerHouse Gym',
        'city': 'Lahore',
      },
    ];

    for (final g in gyms) {
      final ref = _db.collection('gyms').doc(g['id'] as String);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          'name': g['name'],
          'city': g['city'],
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
