import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Yerel hafıza için ekledik
import 'register_screen.dart';
import 'musteri_home_screen.dart';
import 'sofor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false; // Beni hatırla durumu

  @override
  void initState() {
    super.initState();
    _hatirlananBilgileriYukle(); // Ekran açılırken hafızaya bakacak
  }

  // Hafızada kayıtlı mail/şifre varsa kutulara doldurur
  void _hatirlananBilgileriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  // Giriş başarılıysa bilgileri hafızaya kaydeder veya siler
  void _bilgileriKaydet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _girisYap() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta ve şifrenizi girin!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Giriş başarılıysa beni hatırla ayarını çalıştır
      _bilgileriKaydet();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        String rol = userDoc['rol'];

        if (rol == 'Müşteri') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MusteriHomeScreen()));
        } else if (rol == 'Şoför') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SoforHomeScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı bilgileri veritabanında bulunamadı!'), backgroundColor: Colors.red),
        );
      }

    } on FirebaseAuthException catch (e) {
      String mesaj = "Giriş başarısız.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mesaj = 'Hatalı e-posta veya şifre girdiniz.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nakliyat Sistemine Giriş'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 10),
            
            // BENİ HATIRLA ONAY KUTUSU
            CheckboxListTile(
              title: const Text("Beni Hatırla"),
              value: _rememberMe,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            
            _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _girisYap,
                    child: const Text('Giriş Yap', style: TextStyle(fontSize: 18)),
                  ),
            
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text('Hesabın yok mu? Yeni Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}