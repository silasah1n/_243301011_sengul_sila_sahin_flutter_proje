class ValidatorService {
  /// Email formatı kontrol eder
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi boş olamaz';
    }

    // Basit email regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Lütfen geçerli bir e-posta adresi girin';
    }

    return null;
  }

  /// Şifre güvenliği kontrol eder
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş olamaz';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    // Güçlü şifre kontrolü (isteğe bağlı)
    // En az 1 büyük harf, 1 küçük harf, 1 sayı gerektir
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));

    // Şu anda sadece minimum uzunluk kontrolü yapıyoruz
    // İsteğe bağlı olarak güçlü şifre kontrolü ekleyebilirsin:
    /*
    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return 'Şifre büyük harf, küçük harf ve rakam içermelidir';
    }
    */

    return null;
  }

  /// Ad/Soyad validasyonu
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş olamaz';
    }

    if (value.length < 2) {
      return 'En az 2 karakter giriniz';
    }

    if (value.length > 50) {
      return 'En fazla 50 karakter girebilirsiniz';
    }

    // Sadece harfler ve boşluk
    if (!RegExp(r'^[a-zA-ZçğıöşüÇĞİÖŞÜ\s]+$').hasMatch(value)) {
      return 'Sadece harfler ve boşluk girilebilir';
    }

    return null;
  }

  /// Fiyat validasyonu
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fiyat boş olamaz';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Lütfen geçerli bir fiyat girin';
    }

    if (price <= 0) {
      return 'Fiyat 0\'dan büyük olmalıdır';
    }

    if (price > 100000) {
      return 'Fiyat 100000\'i aşamaz';
    }

    return null;
  }

  /// Şehir seçimi validasyonu
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen bir şehir seçiniz';
    }

    return null;
  }

  /// Aynı şehriye gitmesi kontrolü
  static String? validateDifferentCities(String from, String to) {
    if (from == to) {
      return 'Kalkış ve varış şehri aynı olamaz';
    }

    return null;
  }

  /// Açıklama validasyonu
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Açıklama boş olamaz';
    }

    if (value.length < 5) {
      return 'Açıklama en az 5 karakter olmalıdır';
    }

    if (value.length > 500) {
      return 'Açıklama 500 karakteri aşamaz';
    }

    return null;
  }
}
