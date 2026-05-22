import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/musteri_home_screen.dart';
import 'screens/sofor_home_screen.dart';

void main() async {
  // Flutter ve Firebase'in doğru çalışması için bu iki satır şart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const NakliyatApp());
}

class NakliyatApp extends StatelessWidget {
  const NakliyatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nakliyat Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
      home: const AuthCheck(),
    );
  }
}

// Firebase Auth durumunu kontrol eden widget
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı kontrolü yapılıyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Eğer kullanıcı giriş yapmışsa, rolüne göre ana sayfaya yönlendir
        if (snapshot.hasData) {
          return const RoleCheck();
        }

        // Eğer giriş yapılmamışsa login sayfasına git
        return const LoginScreen();
      },
    );
  }
}

// Kullanıcının rolünü kontrol eden widget
class RoleCheck extends StatelessWidget {
  const RoleCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final rol = snapshot.data;

        if (rol == 'Müşteri') {
          return const MusteriHomeScreen();
        } else if (rol == 'Şoför') {
          return const SoforHomeScreen();
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Kullanıcı rolü bulunamadı.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text('Çıkış Yap'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['rol'] as String?;
    } catch (e) {
      return null;
    }
  }
}






