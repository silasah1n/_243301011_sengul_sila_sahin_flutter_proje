import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'ilan_ekle_screen.dart';
import 'ilan_detay_screen.dart';
import 'profile_screen.dart';

class MusteriHomeScreen extends StatelessWidget {
  const MusteriHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? mevcutKullaniciUid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Müşteri Paneli'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.cikisYap();
              },
            )
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif İlanlarım'),
              Tab(text: 'Geçmiş / Tamamlanan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. SEKME: AKTİF İLANLAR
            _ilanListesiGetir(mevcutKullaniciUid, true),
            // 2. SEKME: GEÇMİŞ İLANLAR
            _ilanListesiGetir(mevcutKullaniciUid, false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const IlanEkleScreen()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _ilanListesiGetir(String? uid, bool aktifMi) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ilanlar')
          .where('musteriUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        var ilanlar = snapshot.data?.docs ?? [];
        
        // Filtreleme: Aktifler (Beklemede veya Kabul Edildi), Geçmiş (Teslim Edildi)
        if (aktifMi) {
          ilanlar = ilanlar.where((d) => d['durum'] != 'Teslim Edildi').toList();
        } else {
          ilanlar = ilanlar.where((d) => d['durum'] == 'Teslim Edildi').toList();
        }

        if (ilanlar.isEmpty) return const Center(child: Text('Henüz bir ilan bulunmuyor.'));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: ilanlar.length,
          itemBuilder: (context, index) {
            // Firestore doküman ID'sini ve verilerini alıyoruz
            final String ilanId = ilanlar[index].id;
            final ilan = ilanlar[index].data() as Map<String, dynamic>;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 15),
              // 🎯 TIKLAMA ÖZELLİĞİ İÇİN INKWELL EKLEDİK
              child: InkWell(
                borderRadius: BorderRadius.circular(8), // Kart kenarlarına uyum sağlasın diye
                onTap: () {
                  // İlana tıklandığında Detay Ekranına gidiyor
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IlanDetayScreen(
                        ilanId: ilanId,
                        ilanData: ilan,
                        isSofor: false, // 🎯 Müşteri ekranı olduğu için FALSE yaptık
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ilan['nereden']} ➔ ${ilan['nereye']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      Text('Durum: ${ilan['durum']}', style: TextStyle(color: _durumRengi(ilan['durum']), fontWeight: FontWeight.bold)),
                      
                      // Şoför Bilgisini Gösterme (Eğer şoför kabul ettiyse)
                      if (ilan['soforEmail'] != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: Colors.blue),
                            const SizedBox(width: 5),
                            Text('Şoför: ${ilan['soforEmail']}', style: const TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 10),
                      Text('Teklif Edilen Fiyat: ${ilan['fiyat']} TL'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _durumRengi(String durum) {
    if (durum == 'Beklemede') return Colors.orange;
    if (durum == 'Şoför Kabul Etti') return Colors.blue;
    return Colors.green;
  }
}