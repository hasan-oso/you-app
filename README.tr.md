<div align="center">

# YOU — Akıllı Sağlık Koçunuz

**Flutter ile geliştirilmiş, yapay zeka destekli kişisel sağlık koçu.**

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://play.google.com/store)
[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.2-blue.svg)](pubspec.yaml)

[English](README.md) · [العربية](README.ar.md) · [Türkçe](README.tr.md)

</div>

---

## Genel Bakış

**YOU**, yapay zeka destekli yemek taraması, kişiselleştirilmiş antrenman planları, adım takibi ve alışkanlık oyunlaştırmasını tek bir deneyimde birleştiren çapraz platform bir mobil sağlık uygulamasıdır. Kullanıcıların eyleme dönük içgörüler, günlük görevler ve rütbe ilerleme sistemi aracılığıyla daha sağlıklı günlük rutinler oluşturmasına yardımcı olur.

Şu anda Google Play'de canlı. Flutter, Supabase ve Google Gemini AI ile geliştirilmiştir.

## Temel Özellikler

- **Yapay Zeka Yemek Tarayıcı** — Yemeğinizin fotoğrafını çekin; Google Gemini ile anında besin değeri analizi, zararlı içerik uyarıları ve kişisel sağlık puanı alın.
- **Kişiselleştirilmiş Antrenman Planları** — Kullanıcının biyometrik verileri, yaşam tarzı ve hedeflerine göre uyarlanan rutinler.
- **Adım Takibi** — Cihazın yerel pedometre entegrasyonu, günlük hedefler ve görsel ilerleme göstergeleri.
- **Günlük Sağlık Görevleri** — Sürekliliği coin, rütbe yükseltmeleri ve başarımlarla ödüllendiren oyunlaştırılmış görevler.
- **Akıllı Bildirimler** — Su, yemek ve aktivite için, kullanıcının diline ve saat dilimine duyarlı hatırlatmalar.
- **Önce Gizlilik** — Sağlık verileri açık onayla toplanır ve güvenli biçimde saklanır.
- **Üç Dilli Arayüz** — Tam Arapça (RTL), Türkçe ve İngilizce desteği; tercih edilen dil kalıcı olarak saklanır.
- **Çevrimdışı Öncelikli Mimari** — Yerel SQLite önbelleği ve bağlantı geri geldiğinde Supabase ile uzlaşan bir senkronizasyon kuyruğu.

## Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Çerçeve | Flutter (Dart 3.5+) |
| Durum Yönetimi | GetX |
| Arka Uç / Kimlik Doğrulama | Supabase (PostgreSQL + Auth + Storage) |
| Yapay Zeka | Google Generative AI (Gemini) |
| Yerel Depolama | SQLite (`sqflite`), `shared_preferences` |
| Kimlik Doğrulama | Google Sign-In + Supabase Auth |
| Bildirimler | `flutter_local_notifications` + `timezone` |
| Para Kazanma | Google AdMob (App Open, Rewarded, Banner, Native) |
| Sensörler | `pedometer`, `camera`, `permission_handler` |
| UI / UX | `google_fonts`, `flutter_svg`, `fl_chart`, `confetti`, `shimmer` |

## Mimari

Kod tabanı **özellik öncelikli katmanlı mimari** izler:

```
lib/
├── core/           # Tema, yönlendirme, bağlama, yerelleştirme, ortak bileşenler
├── data/           # Depolar, yerel veri kaynakları, veri modelleri
├── features/       # Özellik modülleri (auth, onboarding, dashboard, profile, history, splash)
│   └── <feature>/
│       ├── controllers/
│       ├── screens/
│       └── widgets/
├── models/         # Alan modelleri (Domain Models)
├── services/       # Kesişen servisler (AI, auth, bildirim, reklam, senkron, DB)
└── main.dart       # Uygulama başlatma ve yaşam döngüsü
```

**Tasarım ilkeleri:**
- Her servis için tek sorumluluk — her servis tek bir konuya sahiptir (kimlik doğrulama, reklamlar, bildirimler vb.).
- Veri erişimi için Repository deseni — arayüz hiçbir zaman uzak API'larla doğrudan konuşmaz.
- Esneklik için senkronizasyon kuyruğu — yazma işlemleri yerel olarak kuyruğa alınır ve bağlantı geri döndüğünde uzlaştırılır.
- Her şey yerele duyarlı — metinler, tarihler, sayılar ve saat dilimleri kullanıcının diline saygı gösterir.

## Başlarken

### Gereksinimler

- Flutter SDK **3.5.0** veya üzeri
- Flutter ve Dart eklentileri yüklü Android Studio veya VS Code
- Android SDK (minimum API **21** / Android 5.0)
- Bir Supabase projesi, bir Gemini API anahtarı ve AdMob uygulama kimlikleri (aşağıya bakın)

### Kurulum

1. **Depoyu klonlayın**
   ```bash
   git clone https://github.com/hasanoso151/you-app.git
   cd you-app
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Ortam değişkenlerini yapılandırın**

   `.env.example` dosyasını `.env` olarak kopyalayın ve kendi kimlik bilgilerinizle doldurun:
   ```bash
   cp .env.example .env
   ```

   Gerekli anahtarlar [`.env.example`](.env.example) içinde belgelenmiştir.

4. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

### Yayın Sürümü Oluşturma

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store için)
flutter build appbundle --release
```

Yayın imzalama için bir Android keystore gerekir. Flutter'ın [uygulama imzalama belgelerine](https://docs.flutter.dev/deployment/android#signing-the-app) bakın.

## Yerelleştirme

Çeviriler `lib/core/localization/` altında yer alır. Uygulama üç dil ile gönderilir:

- `ar_AE` — Arapça (varsayılan, RTL)
- `tr_TR` — Türkçe
- `en_US` — İngilizce

Kullanıcı dili `shared_preferences` içinde kalıcı olarak saklanır ve uygulama yeniden başlatıldığında korunur.

## Gizlilik ve Güvenlik

- Tüm gizli anahtarlar çalışma zamanında `.env` dosyasından yüklenir — hiçbiri ikiliye gömülü değildir.
- API anahtarları, imzalama anahtarları ve kimlik bilgileri [`.gitignore`](.gitignore) ile sürüm kontrolünden hariç tutulur.
- Sağlık verileri Supabase'de, kimliği doğrulanmış kullanıcıya bağlı satır seviyesi güvenlik (RLS) politikaları altında saklanır.
- Güvenlik açığı bildirimi için [SECURITY.md](SECURITY.md) dosyasına bakın.

## Proje Durumu

- **Google Play'de canlı** — sürüm **1.2.2** (yapı 22)
- Yeni yapay zeka tarama yetenekleri ve genişletilmiş yerelleştirme üzerinde aktif geliştirme

## Lisans

Bu proje **Tescilli (Proprietary)** lisansla yayınlanmıştır — tüm hakları saklıdır. Kaynak yalnızca portföy ve eğitim amaçlı görüntüleme için yayınlanmıştır. Tam koşullar için [LICENSE](LICENSE) dosyasına bakın.

## Geliştirici

**[@hasanoso151](https://github.com/hasanoso151)** tarafından geliştirildi ve sürdürülüyor.

Ticari sorular, iş ortaklıkları veya lisanslama talepleri için bir Issue açın veya GitHub üzerinden iletişime geçin.

---

<div align="center">

**Projeyi ilginç bulduysanız, bir ⭐ vermeyi düşünün**

</div>
