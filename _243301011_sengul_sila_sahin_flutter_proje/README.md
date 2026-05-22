# Nakliyat ve Rezervasyon Sistemi

## 📋 Proje Hakkında

**Öğrenci:** Sengül Sıla Şahin  
**Öğrenci No:** 243301011  
**Ders:** Mobil Programlama & Veri Tabanı Yönetim Sistemleri

Nakliyat ve Rezervasyon Sistemi, müşteriler ve şoförler arasında taşıyıcı ilanlarının yayınlanması ve seferlerinin yönetilmesini sağlayan bir Flutter uygulamasıdır.

##  Özellikler

- ✅ **İki Rol Sistemi**: Müşteri ve Şoför
- ✅ **Firebase Authentication**: Güvenli giriş/çıkış
- ✅ **İlan Yönetimi**: İlan oluşturma, listeleme, detaylı görüntüleme
- ✅ **Sefer Üstlenme**: Şoförün seferi kabul etmesi
- ✅ **Profil Yönetimi**: Kullanıcı profili ve istatistikleri
- ✅ **Log Sistemi**: Her işlem kaydedilmesi
- ✅ **Session Kalıcılığı**: Uygulama kapatılıp açıldığında oturum devam ediyor

## 🔐 Test Hesapları

### Müşteri Hesabı
```
📧 E-posta: sila@gmail.com
🔑 Şifre: 123456
👤 Rol: Müşteri
```

### Şoför Hesabı
```
📧 E-posta: ali@gmail.com
🔑 Şifre: 098765
👤 Rol: Şoför
```

## 🏗️ Kullanılan Paketler

```yaml
firebase_core: ^3.0.0              # Firebase initialization
firebase_auth: ^5.7.0              # Authentication
cloud_firestore: ^5.6.12           # Database
shared_preferences: ^2.5.5         # Local storage
```

## 📱 Uygulama Ekranları

### 1. Giriş Ekranı (Login Screen)
- Email ve şifre girişi
- "Beni Hatırla" özelliği
- Yeni hesap oluşturma linkı
- Modern gradient tasarımı

### 2. Kayıt Ekranı (Register Screen)
- Ad, Soyad, Email, Şifre girişi
- Rol seçimi (Müşteri/Şoför)
- Firebase Auth ile kayıt

### 3. Müşteri Ana Sayfası
- Aktif ve Tamamlanan İlanlar sekmesi
- Yeni ilan yayınlama
- İlan detaylarını görüntüleme

### 4. Şoför Ana Sayfası
- Açık İlanlar
- Seferlerim (Aktif Sefer)
- Tamamlananlar
- Sefer üstlenme işlemi

### 5. Profil Ekranı
- Kullanıcı bilgileri (Ad, Soyad, Email, Rol)
- İstatistikler (Yayınlanan İlan / Tamamlanan Sefer)
- Çıkış Yap

## 📊 Firestore Koleksiyonları

### Users Collection
```json
{
  "uid": "user_id",
  "isim": "İsim",
  "soyisim": "Soyisim",
  "eposta": "email@example.com",
  "rol": "Müşteri" | "Şoför",
  "kayitTarihi": Timestamp
}
```

### İlanlar Collection
```json
{
  "musteriUid": "customer_uid",
  "nereden": "Istanbul",
  "nereye": "Ankara",
  "fiyat": 500,
  "aciklama": "Ev taşıması",
  "durum": "Beklemede" | "Şoför Kabul Etti" | "Teslim Edildi",
  "soforUid": "driver_uid",
  "soforEmail": "driver@example.com",
  "tarih": Timestamp
}
```

### Logs Collection
```json
{
  "userId": "user_id",
  "userEmail": "user@example.com",
  "actionType": "LOGIN | LOGOUT | REGISTER | CREATE_ILAN | UPDATE_ILAN | ACCEPT_SEFER | COMPLETE_SEFER",
  "description": "İşlem açıklaması",
  "details": { },
  "timestamp": Timestamp,
  "createdAt": "2026-05-19T..."
}
```

## 🚀 Başlangıç

```bash
# Bağımlılıkları indir
flutter pub get

# Uygulamayı başlat
flutter run
```



*Buraya ekran görüntüleri eklenecek*

---

**Geliştiricisi:** Sengül Sıla Şahin  
**Tarih:** Mayıs 2026
