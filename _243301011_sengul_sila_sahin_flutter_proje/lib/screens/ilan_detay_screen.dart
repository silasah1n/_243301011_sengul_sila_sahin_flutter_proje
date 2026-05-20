import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/log_service.dart';
import 'ilan_ekle_screen.dart';

class IlanDetayScreen extends StatefulWidget {
  final String ilanId;
  final Map<String, dynamic> ilanData;
  final bool isSofor; // Giriş yapan kişi şoför mü?

  const IlanDetayScreen({
    super.key,
    required this.ilanId,
    required this.ilanData,
    required this.isSofor,
  });

  @override
  State<IlanDetayScreen> createState() => _IlanDetayScreenState();
}

class _IlanDetayScreenState extends State<IlanDetayScreen> {
  bool _isLoading = false;

  // Şoförün seferi üstlenmesini sağlayan fonksiyon (SQL'deki sp_SeferUstlen mantığı)
  void _seferiUstlen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? currentDriverUid = FirebaseAuth.instance.currentUser?.uid;
      String? currentDriverEmail = FirebaseAuth.instance.currentUser?.email;

      // Firestore'daki ilgili ilanı güncelliyoruz
      await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanId).update({
        'durum': 'Şoför Kabul Etti',
        'soforUid': currentDriverUid,
        'soforEmail': currentDriverEmail,
      });

      // ✅ SEFER ÜSTLENME LOG'U
      await LogService().logEvent(
        actionType: 'ACCEPT_SEFER',
        description: 'Şoför seferi üstlendi',
        details: {
          'ilanId': widget.ilanId,
          'nereden': widget.ilanData['nereden'],
          'nereye': widget.ilanData['nereye'],
          'fiyat': widget.ilanData['fiyat'],
          'soforEmail': currentDriverEmail,
          'timestamp': DateTime.now().toString(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sefer başarıyla üstlenildi!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // İşlem başarılıysa ana sayfaya dön
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sefer üstlenilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _seferiTamamla() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanId).update({
        'durum': 'Teslim Edildi',
      });

      await LogService().logEvent(
        actionType: 'COMPLETE_SEFER',
        description: 'Sefer teslim edildi',
        details: {
          'ilanId': widget.ilanId,
          'nereden': widget.ilanData['nereden'],
          'nereye': widget.ilanData['nereye'],
          'timestamp': DateTime.now().toString(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sefer tamamlandı!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Müşterinin ilanı silmesi
  void _ilanSil() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanId).delete();

      await LogService().logEvent(
        actionType: 'DELETE_ILAN',
        description: 'İlan silindi',
        details: {
          'ilanId': widget.ilanId,
          'nereden': widget.ilanData['nereden'],
          'nereye': widget.ilanData['nereye'],
          'timestamp': DateTime.now().toString(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlan silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Şoförün sefer iptal etmesi
  void _seferiIptal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seferi İptal Et'),
        content: const Text('Bu seferi iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanId).update({
        'durum': 'Beklemede',
        'soforUid': FieldValue.delete(),
        'soforEmail': FieldValue.delete(),
      });

      await LogService().logEvent(
        actionType: 'CANCEL_SEFER',
        description: 'Sefer iptal edildi',
        details: {
          'ilanId': widget.ilanId,
          'nereden': widget.ilanData['nereden'],
          'nereye': widget.ilanData['nereye'],
          'timestamp': DateTime.now().toString(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sefer başarıyla iptal edildi!'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sefer iptal edilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // İlan verilerini değişkenlere atıyoruz
    String nereden = widget.ilanData['nereden'] ?? 'Belirtilmedi';
    String nereye = widget.ilanData['nereye'] ?? 'Belirtilmedi';
    double fiyat = (widget.ilanData['fiyat'] ?? 0.0).toDouble();
    String aciklama = widget.ilanData['aciklama'] ?? 'Açıklama bulunmuyor.';
    String durum = widget.ilanData['durum'] ?? 'Beklemede';

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Güzergah Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 32),
                        const SizedBox(height: 5),
                        Text(nereden, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Kalkış', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey, size: 28),
                    Column(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 32),
                        const SizedBox(height: 5),
                        Text(nereye, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Varış', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Detay Bilgileri Listesi
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green, size: 30),
              title: const Text('Teklif Edilen Ücret'),
              subtitle: Text('$fiyat TL', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange, size: 30),
              title: const Text('İlan Durumu'),
              subtitle: Text(durum, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Taşınacak Eşya / Açıklama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                aciklama,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
              ),
            ),
            const SizedBox(height: 40),

            if (!widget.isSofor && durum == 'Beklemede') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IlanEkleScreen(
                          ilanId: widget.ilanId,
                          mevcutVeri: widget.ilanData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('İlanı Düzenle', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _ilanSil,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('İlanı Sil', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ),
            ],

            if (widget.isSofor && durum == 'Beklemede')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _seferiUstlen,
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Seferi Üstlen', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ),

            if (widget.isSofor && durum == 'Şoför Kabul Etti') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _seferiTamamla,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Teslim Et (Seferi Bitir)', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _seferiIptal,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Seferi İptal Et', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}