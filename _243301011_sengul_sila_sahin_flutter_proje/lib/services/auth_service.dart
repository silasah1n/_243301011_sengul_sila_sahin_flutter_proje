import 'package:firebase_auth/firebase_auth.dart';
import '../services/log_service.dart';

/// Oturum kapatma ve log kaydı
class AuthService {
  static Future<void> cikisYap() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Bilinmiyor';

    await LogService().logEvent(
      actionType: 'LOGOUT',
      description: 'Kullanıcı çıkış yaptı',
      details: {
        'email': userEmail,
        'timestamp': DateTime.now().toString(),
      },
    );

    await FirebaseAuth.instance.signOut();
  }
}
