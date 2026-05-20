import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/log_service.dart';
import '../services/validator_service.dart';

class IlanEkleScreen extends StatefulWidget {
  final String? ilanId;
  final Map<String, dynamic>? mevcutVeri;

  const IlanEkleScreen({super.key, this.ilanId, this.mevcutVeri});

  bool get duzenlemeModu => ilanId != null;

  @override
  State<IlanEkleScreen> createState() => _IlanEkleScreenState();
}

// Türkiye'nin 81 ili (Osmaniye düzeltildi)
const List<String> turkiyeIlleri = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Ardahan',
  'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl',
  'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
  'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir',
  'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta',
  'İstanbul', 'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu',
  'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya',
  'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde',
  'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas',
  'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova',
  'Yozgat', 'Zonguldak',
];

class _IlanEkleScreenState extends State<IlanEkleScreen> {
  String? _neredenSecilmi;
  String? _nereyeSecilmi;
  final _fiyatController = TextEditingController();
  final _aciklamaController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mevcutVeri != null) {
      _neredenSecilmi = widget.mevcutVeri!['nereden'] as String?;
      _nereyeSecilmi = widget.mevcutVeri!['nereye'] as String?;
      _fiyatController.text = (widget.mevcutVeri!['fiyat'] ?? '').toString();
      _aciklamaController.text = widget.mevcutVeri!['aciklama'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _fiyatController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  void _ilanYayinla() async {
    final neredenHata = ValidatorService.validateCity(_neredenSecilmi);
    final nereyeHata = ValidatorService.validateCity(_nereyeSecilmi);
    final fiyatHata = ValidatorService.validatePrice(_fiyatController.text.trim());
    final sehirFarkHata = _neredenSecilmi != null && _nereyeSecilmi != null
        ? ValidatorService.validateDifferentCities(_neredenSecilmi!, _nereyeSecilmi!)
        : null;

    final hata = neredenHata ?? nereyeHata ?? fiyatHata ?? sehirFarkHata;
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? userUid = FirebaseAuth.instance.currentUser?.uid;
      final fiyat = double.tryParse(_fiyatController.text.trim()) ?? 0.0;
      final aciklama = _aciklamaController.text.trim();

      if (widget.duzenlemeModu) {
        await FirebaseFirestore.instance.collection('ilanlar').doc(widget.ilanId).update({
          'nereden': _neredenSecilmi,
          'nereye': _nereyeSecilmi,
          'fiyat': fiyat,
          'aciklama': aciklama,
          'guncellemeTarihi': Timestamp.now(),
        });
        await LogService().logEvent(
          actionType: 'UPDATE_ILAN',
          description: 'İlan güncellendi',
          details: {
            'ilanId': widget.ilanId,
            'nereden': _neredenSecilmi,
            'nereye': _nereyeSecilmi,
            'fiyat': fiyat,
            'timestamp': DateTime.now().toString(),
          },
        );
      } else {
        await FirebaseFirestore.instance.collection('ilanlar').add({
          'musteriUid': userUid,
          'nereden': _neredenSecilmi,
          'nereye': _nereyeSecilmi,
          'fiyat': fiyat,
          'aciklama': aciklama,
          'durum': 'Beklemede',
          'tarih': Timestamp.now(),
        });
        await LogService().logEvent(
          actionType: 'CREATE_ILAN',
          description: 'Yeni ilan oluşturuldu',
          details: {
            'nereden': _neredenSecilmi,
            'nereye': _nereyeSecilmi,
            'fiyat': fiyat,
            'timestamp': DateTime.now().toString(),
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.duzenlemeModu ? 'İlan güncellendi!' : 'İlan başarıyla yayınlandı!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlan eklenirken hata oluştu: $e'),
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

  // Geliştirilmiş ve Hataları Giderilmiş Şehir Seçim Diyaloğu
  void _sehirSec(BuildContext context, bool nereden) {
    String aramaMetni = '';
    List<String> filtreliIller = List.from(turkiyeIlleri);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(nereden ? 'Kalkış Şehrini Seç' : 'Varış Şehrini Seç'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5, // Ekrana göre dinamik yükseklik kısıtı
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        // Diyalog içindeki listeyi güncellemek için setDialogState kullanıyoruz
                        setDialogState(() {
                          aramaMetni = value;
                          if (aramaMetni.isEmpty) {
                            filtreliIller = turkiyeIlleri;
                          } else {
                            filtreliIller = turkiyeIlleri
                                .where((il) => il.toLowerCase().startsWith(aramaMetni.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Şehir adı yazın...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtreliIller.isEmpty
                          ? const Center(child: Text('Şehir bulunamadı.'))
                          : ListView.builder(
                              itemCount: filtreliIller.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(filtreliIller[index]),
                                  onTap: () {
                                    // Ana ekranın durumunu güncellemek için sınıfın kendi setState'ini çağırıyoruz
                                    setState(() {
                                      if (nereden) {
                                        _neredenSecilmi = filtreliIller[index];
                                      } else {
                                        _nereyeSecilmi = filtreliIller[index];
                                      }
                                    });
                                    Navigator.pop(dialogContext); // Diyaloğu kapat
                                  },
                                );
                              },
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.duzenlemeModu ? 'İlanı Düzenle' : 'Yeni Nakliyat İlanı Aç'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Nereden Şehir Seçim
            GestureDetector(
              onTap: () => _sehirSec(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _neredenSecilmi ?? 'Kalkış Şehrini Seç',
                        style: TextStyle(
                          fontSize: 16,
                          color: _neredenSecilmi == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Nereye Şehir Seçim
            GestureDetector(
              onTap: () => _sehirSec(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.red),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _nereyeSecilmi ?? 'Varış Şehrini Seç',
                        style: TextStyle(
                          fontSize: 16,
                          color: _nereyeSecilmi == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _fiyatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Teklif Edilen Fiyat (TL)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _aciklamaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Taşınacak Eşya / Açıklama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _ilanYayinla,
                    child: Text(
                      widget.duzenlemeModu ? 'Değişiklikleri Kaydet' : 'İlanı Yayınla',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}