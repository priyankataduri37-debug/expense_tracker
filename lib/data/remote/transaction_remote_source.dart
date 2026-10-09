import 'package:cloud_firestore/cloud_firestore.dart';

class RemoteTransaction {
  const RemoteTransaction(this.data, this.serverMicros);
  final Map<String, dynamic> data;
  final int serverMicros;
}

class TransactionRemoteSource {
  TransactionRemoteSource([FirebaseFirestore? firestore])
    : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _fs.collection('users').doc(uid).collection('transactions');

  Future<void> upsert(String uid, Map<String, dynamic> data) {
    return _col(uid).doc(data['id'] as String).set({
      ...data,
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<RemoteTransaction>> fetchChangedSince(
    String uid,
    int? sinceMicros,
  ) async {
    Query<Map<String, dynamic>> q = _col(uid).orderBy('serverUpdatedAt');
    if (sinceMicros != null) {
      q = q.where(
        'serverUpdatedAt',
        isGreaterThan: Timestamp.fromMicrosecondsSinceEpoch(sinceMicros),
      );
    }
    final snap = await q.get();

    final result = <RemoteTransaction>[];
    for (final d in snap.docs) {
      final data = d.data();
      final ts = data.remove('serverUpdatedAt');
      if (ts is Timestamp) {
        result.add(RemoteTransaction(data, ts.microsecondsSinceEpoch));
      }
    }
    return result;
  }
}
