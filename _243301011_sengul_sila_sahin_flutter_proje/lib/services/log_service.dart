import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sistem günlüğüne log kaydı ekler
  Future<void> logEvent({
    required String actionType, // 'LOGIN', 'LOGOUT', 'CREATE_ILAN', 'ACCEPT_SEFER', vb.
    required String description, // Açıklama
    Map<String, dynamic>? details, // Ek detaylar
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email ?? 'Anonymous';

      await _firestore.collection('logs').add({
        'userId': userId,
        'userEmail': userEmail,
        'actionType': actionType,
        'description': description,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      print('✅ Log kaydedildi: $actionType - $description');
    } catch (e) {
      print('❌ Log kaydı hatası: $e');
    }
  }

  /// Kullanıcının tüm aktivitesini getirir
  Stream<QuerySnapshot> getUserLogs(String userId) {
    return _firestore
        .collection('logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Sistem genelinde tüm logları getirir (Admin için)
  Stream<QuerySnapshot> getAllLogs() {
    return _firestore
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
}
