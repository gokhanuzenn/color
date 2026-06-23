import 'dart:ui';

class L {
  static String get languageCode => PlatformDispatcher.instance.locale.languageCode;
  static bool get isTr => languageCode == 'tr';

  static String get appTitle => isTr ? 'BOYAMA DÜNYASI' : 'COLOR WORLD';
  static String get selectCategory => isTr ? 'Kategori Seçin' : 'Select Category';
  static String get promoCode => isTr ? 'PROMOSYON KODU' : 'PROMO CODE';
  static String get enterCode => isTr ? 'Kodu buraya yazın...' : 'Enter code here...';
  static String get cancel => isTr ? 'İPTAL' : 'CANCEL';
  static String get confirm => isTr ? 'ONAYLA' : 'CONFIRM';
  static String get codeAccepted => isTr ? 'Tebrikler! Kod kabul edildi.' : 'Congratulations! Code accepted.';
  static String get invalidCode => isTr ? 'Geçersiz kod!' : 'Invalid code!';
  static String get removeAds => isTr ? 'REKLAMLARI KALDIR ($2.99)' : 'REMOVE ADS ($2.99)';
  static String get adsRemoved => isTr ? 'Reklamlar kaldırıldı! Teşekkürler.' : 'Ads removed! Thank you.';
  static String get imagesCount => isTr ? 'GÖRSEL' : 'IMAGES';
  
  static String get selectImageToColor => isTr ? 'Boyamak istediğin resmi seç' : 'Select an image to color';
  
  static String get save => isTr ? 'KAYDET' : 'SAVE';
  static String get imageSaved => isTr ? 'RESİM GALERİYE KAYDEDİLDİ!' : 'IMAGE SAVED TO GALLERY!';
  static String get errorSaving => isTr ? 'KAYDEDİLİRKEN HATA OLUŞTU.' : 'ERROR SAVING IMAGE.';
  static String get size => isTr ? 'BOYUT' : 'SIZE';
  
  static String get pencil => isTr ? 'Kalem' : 'Pencil';
  static String get brush => isTr ? 'Fırça' : 'Brush';
  static String get eraser => isTr ? 'Silgi' : 'Eraser';
  
  static String get crayon => isTr ? 'Kurşun' : 'Crayon';
  static String get charcoal => isTr ? 'Kömür' : 'Charcoal';
  static String get watercolor => isTr ? 'Sulu' : 'Watercolor';
  static String get marker => isTr ? 'Keçeli' : 'Marker';
  static String get classic => isTr ? 'Klasik' : 'Classic';
  static String get dryBrush => isTr ? 'Kuru' : 'Dry Brush';

  static String get loadingAd => isTr ? 'Reklam Yükleniyor...' : 'Loading Ad...';
  static String get ready => isTr ? 'Hazır!' : 'Ready!';
  static String get preparingImage => isTr ? 'Resim boyanmaya hazırlanıyor!' : 'Preparing the image for coloring!';

  static String categoryName(String id) {
    switch (id) {
      case 'sevimli_dostlar': return isTr ? 'Hayvanlar' : 'Animals';
      case 'vahsi_dostlar': return isTr ? 'Vahşi Dostlar' : 'Wild Friends';
      case 'dinozor': return isTr ? 'Dinozor Dünyası' : 'Dinosaur World';
      case 'ciftlik': return isTr ? 'Çiftlik' : 'Farm';
      case 'tasitlar': return isTr ? 'Taşıtlar' : 'Vehicles';
      case 'insaat': return isTr ? 'İş Arabaları' : 'Construction';
      case 'uzay': return isTr ? 'Uzay Maceraları' : 'Space Adventures';
      case 'okyanus': return isTr ? 'Deniz Altı' : 'Under the Sea';
      case 'doga': return isTr ? 'Doğa' : 'Nature';
      case 'yiyecekler': return isTr ? 'Yiyecekler' : 'Food';
      case 'sayilar': return isTr ? 'Sayılar' : 'Numbers';
      case 'harfler': return isTr ? 'Harfler Dünyası' : 'World of Letters';
      case 'erkek_karakter': return isTr ? 'Erkek Karakter' : 'Boy Character';
      case 'kiz_karakter': return isTr ? 'Kız Karakter' : 'Girl Character';
      case 'kahraman': return isTr ? 'Kahramanlar' : 'Heroes';
      case 'meslekler': return isTr ? 'Meslekler' : 'Jobs';
      case 'oyuncak': return isTr ? 'Oyuncak Dünyası' : 'Toy World';
      case 'robot': return isTr ? 'Robotlar' : 'Robots';
      case 'emo_kategori': return isTr ? 'Emojiler' : 'Emojis';
      case 'masal': return isTr ? 'Masallar' : 'Fairy Tales';
      case 'canavar': return isTr ? 'Canavarlar' : 'Monsters';
      default: return id;
    }
  }
}
