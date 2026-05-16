import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Müşteri';

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _kayitOl() async {
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // 1. Adım: Firebase Auth ile Kullanıcı Oluşturma
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Adım: Firestore'a Ek Bilgileri Kaydetme
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'isim': _nameController.text.trim(),
        'soyisim': _surnameController.text.trim(),
        'eposta': _emailController.text.trim(),
        'rol': _selectedRole,
        'kayitTarihi': Timestamp.now(),
      });

      // --- [KRİTİK KONTROL] ---
      // Eğer bu süreçte kullanıcı ekrandan ayrıldıysa aşağıyı çalıştırma, çökmesi engellenir.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt Başarılı! Giriş yapabilirsiniz.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String mesaj = "Bir hata oluştu.";
      if (e.code == 'weak-password') {
        mesaj = 'Şifre çok zayıf (En az 6 karakter olmalı).';
      } else if (e.code == 'email-already-in-use') {
        mesaj = 'Bu e-posta adresiyle zaten bir hesap var.';
      } else if (e.code == 'invalid-email') {
        mesaj = 'Geçersiz bir e-posta adresi girdiniz.';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
      );
    } catch (e) {
      // Eğer Firestore kilitliyse hatayı ekranda net görmek için burayı güncelledik
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veritabanı İzin Hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kayıt Oluştur'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Soyisim', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Sistemdeki Rolünüz', border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment_ind)),
              items: const [
                DropdownMenuItem(value: 'Müşteri', child: Text('Müşteri (Rezervasyon Yapacak)')),
                DropdownMenuItem(value: 'Şoför', child: Text('Şoför (Sefer Üstlenecek)')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedRole = val!;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _kayitOl,
              child: const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}