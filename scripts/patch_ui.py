import re, os

ROOT = 'D:/2026/1.Jan/4.Fitbud/fitbud/lib/'


def rd(p):
    return open(ROOT + p, encoding='utf-8').read()


def wr(p, s):
    open(ROOT + p, 'w', encoding='utf-8').write(s)


def sub(p, pairs):
    s = rd(p)
    for a, b in pairs:
        if a not in s:
            print('MISSING in', p, ':', a[:70].replace('\n', ' '))
        s = s.replace(a, b)
    wr(p, s)


# ---------------- scan repo: map-based stream for the history screens
sub('domain/repos/scans/scan_repo.dart', [
    ("  Future<Map<String, dynamic>> _scanGym({",
     """  /// Raw camelCase scan maps (`scannedAt` as DateTime) for the history
  /// screens; optionally limited to one gym.
  Stream<List<Map<String, dynamic>>> watchScanMaps({String? gymId, int limit = 500}) {
    final uid = requireUid();
    return db
        .from('scans')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('scanned_at', ascending: false)
        .limit(limit)
        .map((rows) => rows
            .where((r) => gymId == null || r['gym_id'] == gymId)
            .map((r) {
              final m = DbRow.toCamel(r);
              m['scannedAt'] = DateTime.tryParse('${r['scanned_at']}')?.toLocal();
              return m;
            })
            .toList());
  }

  Future<Map<String, dynamic>> _scanGym({"""),
])

# ---------------- scan history screens
sub('presentation/screens/scanning/scan_history_screen.dart', [
    ("import 'package:cloud_firestore/cloud_firestore.dart';\n", ""),
    ("import '../../../firebase_instances.dart';\n",
     "import '../../../data/supabase_instances.dart';\nimport '../../../domain/repos/repo_provider.dart';\n"),
    ("FirebaseInstances.auth.currentUser?.uid", "SupabaseInstances.uid"),
    ("StreamBuilder<QuerySnapshot<Map<String, dynamic>>>", "StreamBuilder<List<Map<String, dynamic>>>"),
    ("""stream: FirebaseInstances.db
            .collection('scans')
            .where('userId', isEqualTo: uid)
            .orderBy('scannedAt', descending: true)
            .snapshots(),""", "stream: Get.find<Repos>().scanRepo.watchScanMaps(),"),
    ("snap.data?.docs ?? []", "snap.data ?? []"),
    ("Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byGym", "Map<String, List<Map<String, dynamic>>> byGym"),
    ("scans.first['scannedAt'] as Timestamp?", "scans.first['scannedAt'] as DateTime?"),
    ("DateFormat('dd MMM yyyy').format(lastTs.toDate())", "DateFormat('dd MMM yyyy').format(lastTs)"),
])
sub('presentation/screens/scanning/gym_scan_history_screen.dart', [
    ("import 'package:cloud_firestore/cloud_firestore.dart';\n", ""),
    ("import '../../../firebase_instances.dart';\n",
     "import '../../../domain/repos/repo_provider.dart';\n"),
    ("    final uid = FirebaseInstances.auth.currentUser!.uid;\n\n", ""),
    ("StreamBuilder<QuerySnapshot<Map<String, dynamic>>>", "StreamBuilder<List<Map<String, dynamic>>>"),
    ("""stream: FirebaseInstances.db
            .collection('scans')
            .where('userId', isEqualTo: uid)
            .where('gymId', isEqualTo: gymId)
            .orderBy('scannedAt', descending: true)
            .snapshots(),""", "stream: Get.find<Repos>().scanRepo.watchScanMaps(gymId: gymId),"),
    ("snap.data?.docs ?? []", "snap.data ?? []"),
    ("final d = docs[i].data();", "final d = docs[i];"),
    ("final ts = d['scannedAt'] as Timestamp?;", "final ts = d['scannedAt'] as DateTime?;"),
    ("DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())", "DateFormat('dd MMM yyyy, hh:mm a').format(ts)"),
])
sub('presentation/screens/scanning/scan_detail_screen.dart', [
    ("format(ts.toDate())", "format(ts is DateTime ? ts : ts.toDate())"),
])
sub('presentation/screens/gyms/widgets/gym_user_scans_section.dart', [
    ("import 'package:cloud_firestore/cloud_firestore.dart';\n", "import 'package:get/get.dart';\n"),
    ("import '../../../../firebase_instances.dart';\n",
     "import '../../../../data/supabase_instances.dart';\nimport '../../../../domain/repos/repo_provider.dart';\n"),
    ("FirebaseInstances.auth.currentUser?.uid", "SupabaseInstances.uid"),
    ("""    final query = FirebaseInstances.db
        .collection('scans')
        .where('userId', isEqualTo: uid)
        .where('gymId', isEqualTo: gymId)
        .orderBy('scannedAt', descending: true)
        .limit(10);

""", ""),
    ("StreamBuilder<QuerySnapshot<Map<String, dynamic>>>", "StreamBuilder<List<Map<String, dynamic>>>"),
    ("stream: query.snapshots(),", "stream: Get.find<Repos>().scanRepo.watchScanMaps(gymId: gymId, limit: 10),"),
    ("snapshot.data!.docs.isEmpty", "snapshot.data!.isEmpty"),
    ("snapshot.data!.docs.length", "snapshot.data!.length"),
    ("final d = snapshot.data!.docs[index].data();", "final d = snapshot.data![index];"),
    ("final ts = d['scannedAt'] as Timestamp?;", "final ts = d['scannedAt'] as DateTime?;"),
    ("""                    .format(ts.toDate())""", """                    .format(ts)"""),
])

# ---------------- location controller
sub('presentation/screens/authentication/controllers/location_controller.dart', [
    ("import 'package:firebase_auth/firebase_auth.dart';\n", "import 'package:supabase_flutter/supabase_flutter.dart' show User;\n"),
    ("import '../../../../firebase_instances.dart';\n", ""),
    ("  final FirebaseAuth _auth = FirebaseInstances.auth;\n", ""),
    ("_auth.authStateChanges().listen((u) {\n      final uid = u?.uid;",
     "_authRepo.authState().listen((u) {\n      final uid = u?.id;"),
])

# ---------------- home controller
s = rd('presentation/screens/home/home_controller.dart')
s = s.replace("import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\n",
              "import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, User;\n")
s = s.replace("import '../../../firebase_instances.dart';\n", "import '../../../data/doc.dart';\nimport '../../../data/supabase_instances.dart';\n")
s = s.replace("""  HomeController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseInstances.db,
        _sessionRepo = SessionRepo(
          db ?? FirebaseInstances.db,
          auth ?? FirebaseInstances.auth,
        );

  final FirebaseFirestore _db;
""", """  HomeController({SupabaseClient? db})
      : _db = db ?? SupabaseInstances.client,
        _sessionRepo = SessionRepo(db ?? SupabaseInstances.client);

  final SupabaseClient _db;
""")
s = s.replace("""      final snap = await _db
          .collection('activities')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));

      activities.assignAll(
        snap.docs.map((d) => Activity.fromDoc(d)).toList(),
      );""", """      final rows = await _db
          .from('activities')
          .select()
          .eq('is_active', true)
          .order('order')
          .limit(50);

      activities.assignAll(
        rows.map((r) => Activity.fromDoc(Doc.fromRow(r))).toList(),
      );""")
s = s.replace("""    _prodSub = _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      products.assignAll(snap.docs.map((d) => Product.fromDoc(d)));""", """    _prodSub = _db
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(10)
        .listen((rows) {
      products.assignAll(rows.map((r) => Product.fromDoc(Doc.fromRow(r))));""")
wr('presentation/screens/home/home_controller.dart', s)

# ---------------- plans controller
s = rd('presentation/screens/subscription/plans_controller.dart')
s = s.replace("import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\n",
              "import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;\n")
s = s.replace("import '../../../firebase_instances.dart';\n", "import '../../../data/doc.dart';\nimport '../../../data/supabase_instances.dart';\n")
s = s.replace("""  PremiumPlanController({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseInstances.db,
        _auth = auth ?? FirebaseInstances.auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
""", """  PremiumPlanController({SupabaseClient? db}) : _db = db ?? SupabaseInstances.client;

  final SupabaseClient _db;
""")
s = s.replace("""  // Cloud Functions to implement: "directPayCreatePaymentUrl" and
  // "directPayFinalizeFromRedirect" (region: asia-south1), redirecting to
  // https://fitbud-46f70.web.app/payments/success and .../failed.""", """  // Edge functions to implement: "directpay-create-payment-url" and
  // "directpay-finalize" (supabase/functions), redirecting to your
  // payments success / failed pages.""")
s = s.replace("""    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final subRef =
    _db.collection('users').doc(uid).collection('subscriptions').doc(orderId);

    await subRef.set({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));""", """    // Subscription rows are server-write-only (RLS): cancelling a pending
    // order has to go through a trusted backend once payments exist.
    throw PaymentsUnavailableException();""")
s = s.replace("""    _plansSub = _db
        .collection('plans')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      plans.value = snap.docs.map((d) => Plan.fromDoc(d)).toList();""", """    _plansSub = _db
        .from('plans')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .listen((rows) {
      plans.value = rows.map((r) => Plan.fromDoc(Doc.fromRow(r))).toList();""")
s = s.replace("""    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _meSub?.cancel();
    _meSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) {
        me.value = null;
        return;
      }
      me.value = AppUser.fromDoc(snap);""", """    final uid = SupabaseInstances.uid;
    if (uid == null) return;

    _meSub?.cancel();
    _meSub = _db.from('profiles').stream(primaryKey: ['id']).eq('id', uid).listen((rows) {
      if (rows.isEmpty) {
        me.value = null;
        return;
      }
      me.value = AppUser.fromDoc(Doc.fromRow(rows.first));""")
wr('presentation/screens/subscription/plans_controller.dart', s)

# ---------------- create group sheet
sub('common/bottom_sheets/create_group_sheet.dart', [
    ("""    final ref = FirebaseStorage.instance.ref().child('groups/$groupId/avatar.jpg');
    await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();""",
     """    return repos.mediaRepo.uploadGroupAvatarBytes(groupId: groupId, bytes: _imageBytes!);"""),
])

# ---------------- app binding
sub('app_binding.dart', [
    ("import 'firebase_instances.dart';\n", ""),
    ("""    Get.put<ScanRepo>(
      ScanRepo(
        FirebaseInstances.db,
        FirebaseInstances.auth,
        FirebaseInstances.functions,
      ),
      permanent: true,
    );""", """    Get.put<ScanRepo>(Get.find<Repos>().scanRepo, permanent: true);"""),
])
print('done')
