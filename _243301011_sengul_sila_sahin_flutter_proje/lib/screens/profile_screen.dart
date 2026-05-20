import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final rol = userData['rol'] as String? ?? '';

      int ilanCount = 0;
      int completedCount = 0;
      int toplamSefer = 0;

      if (rol == 'Müşteri') {
        final sonuc = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('musteriUid', isEqualTo: user.uid)
            .count()
            .get();
        ilanCount = sonuc.count ?? 0;
      } else if (rol == 'Şoför') {
        final tamamlanan = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('soforUid', isEqualTo: user.uid)
            .where('durum', isEqualTo: 'Teslim Edildi')
            .count()
            .get();
        final toplam = await FirebaseFirestore.instance
            .collection('ilanlar')
            .where('soforUid', isEqualTo: user.uid)
            .count()
            .get();
        completedCount = tamamlanan.count ?? 0;
        toplamSefer = toplam.count ?? 0;
      }

      return {
        ...userData,
        'email': user.email,
        'ilanCount': ilanCount,
        'completedCount': completedCount,
        'toplamSefer': toplamSefer,
      };
    } catch (e) {
      print('Profil yükleme hatası: $e');
      return {};
    }
  }

  void _logout() async {
    await AuthService.cikisYap();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Profil bilgisi yüklenemedi'));
          }

          final userData = snapshot.data!;
          final isim = userData['isim'] ?? 'Bilinmiyor';
          final soyisim = userData['soyisim'] ?? 'Bilinmiyor';
          final email = userData['email'] ?? 'Bilinmiyor';
          final rol = userData['rol'] ?? 'Bilinmiyor';
          final kayitTarihi = userData['kayitTarihi'];
          final ilanCount = userData['ilanCount'] ?? 0;
          final completedCount = userData['completedCount'] ?? 0;
          final toplamSefer = userData['toplamSefer'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ KULLANICI ÖZETİ KARTI
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: rol == 'Müşteri'
                            ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                            : [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            rol == 'Müşteri' ? Icons.person : Icons.local_shipping,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '$isim $soyisim',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rol,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ✅ BİLGİ KARTLARI
                _buildInfoCard('📧 E-Posta', email),
                const SizedBox(height: 15),
                _buildInfoCard('👤 Rol', rol),
                const SizedBox(height: 15),
                if (kayitTarihi != null)
                  _buildInfoCard(
                    '📅 Kayıt Tarihi',
                    kayitTarihi.toDate().toString().split('.')[0],
                  ),
                const SizedBox(height: 30),

                // ✅ İSTATİSTİKLER
                if (rol == 'Müşteri')
                  _buildStatistics('Yayınlanan İlanlar', ilanCount.toString(), Colors.blue)
                else
                  Column(
                    children: [
                      _buildStatistics('Tamamlanan Sefer', completedCount.toString(), Colors.green),
                      const SizedBox(height: 15),
                      _buildStatistics(
                        'Toplam Sefer',
                        toplamSefer.toString(),
                        Colors.orange,
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // ✅ ÇIKIŞ BUTONU
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(String title, String value, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
