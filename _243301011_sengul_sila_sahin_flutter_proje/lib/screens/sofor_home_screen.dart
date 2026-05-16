import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SoforHomeScreen extends StatefulWidget {
  const SoforHomeScreen({super.key});

  @override
  State<SoforHomeScreen> createState() => _SoforHomeScreenState();
}

class _SoforHomeScreenState extends State<SoforHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final String? mevcutSoforUid = FirebaseAuth.instance.currentUser?.uid;
    final String? mevcutSoforEmail = FirebaseAuth.instance.currentUser?.email;

    return DefaultTabController(
      length: 3, // 3 Sekmeye çıkardık
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Şoför Yönetim Paneli'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/');
              },
            )
          ],
          bottom: const TabBar(
            isScrollable: true, // Sekmeler sığsın diye kaydırılabilir yaptık
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Açık İlanlar'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Seferlerim'),
              Tab(icon: Icon(Icons.history), text: 'Tamamlananlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. SEKME: AÇIK İLANLAR
            _ilanListesiGetir(
              stream: FirebaseFirestore.instance.collection('ilanlar').where('durum', isEqualTo: 'Beklemede').snapshots(),
              tabTipi: 'acik',
              mevcutSoforUid: mevcutSoforUid,
              mevcutSoforEmail: mevcutSoforEmail,
            ),
            // 2. SEKME: SEFERLERİM (Aktif olanlar)
            _ilanListesiGetir(
              stream: FirebaseFirestore.instance.collection('ilanlar').where('soforUid', isEqualTo: mevcutSoforUid).snapshots(),
              tabTipi: 'aktif',
              mevcutSoforUid: mevcutSoforUid,
            ),
            // 3. SEKME: TAMAMLANANLAR
            _ilanListesiGetir(
              stream: FirebaseFirestore.instance.collection('ilanlar').where('soforUid', isEqualTo: mevcutSoforUid).snapshots(),
              tabTipi: 'tamamlanan',
              mevcutSoforUid: mevcutSoforUid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ilanListesiGetir({required Stream<QuerySnapshot> stream, required String tabTipi, String? mevcutSoforUid, String? mevcutSoforEmail}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        var ilanlar = snapshot.data?.docs ?? [];
        
        // Dart tarafında filtreleme (Client-side filtering)
        if (tabTipi == 'aktif') {
          ilanlar = ilanlar.where((d) => d['durum'] == 'Şoför Kabul Etti').toList();
        } else if (tabTipi == 'tamamlanan') {
          ilanlar = ilanlar.where((d) => d['durum'] == 'Teslim Edildi').toList();
        }

        if (ilanlar.isEmpty) return const Center(child: Text('Burada henüz bir ilan yok.', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: ilanlar.length,
          itemBuilder: (context, index) {
            final doc = ilanlar[index];
            final ilan = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${ilan['nereden']} ➔ ${ilan['nereye']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Fiyat: ${ilan['fiyat']} TL', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    if (tabTipi == 'acik')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('ilanlar').doc(doc.id).update({
                            'durum': 'Şoför Kabul Etti',
                            'soforUid': mevcutSoforUid,
                            'soforEmail': mevcutSoforEmail, // Müşterinin görmesi için ekledik
                          });
                        },
                        child: const Text('Seferi Üstlen'),
                      ),
                    
                    if (tabTipi == 'aktif')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('ilanlar').doc(doc.id).update({'durum': 'Teslim Edildi'});
                        },
                        child: const Text('Teslim Et (Seferi Bitir)'),
                      ),

                    if (tabTipi == 'tamamlanan')
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 5),
                          Text('Bu sefer başarıyla tamamlandı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}