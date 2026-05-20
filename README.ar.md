<div align="center" dir="rtl">

# YOU — مدربك الصحي الذكي

**رفيق صحي شخصي مدعوم بالذكاء الاصطناعي، مبني باستخدام Flutter.**

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://play.google.com/store)
[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.2-blue.svg)](pubspec.yaml)

[English](README.md) · [العربية](README.ar.md) · [Türkçe](README.tr.md)

</div>

---

<div dir="rtl">

## نظرة عامة

**YOU** هو تطبيق رفيق صحي متعدد المنصات يجمع بين فحص الطعام بالذكاء الاصطناعي، وخطط التمارين المخصصة، وعداد الخطوات، وتلعيب العادات الصحية في تجربة واحدة. يساعد المستخدمين على بناء روتين يومي صحي من خلال رؤى قابلة للتنفيذ، ومهام يومية، ونظام ترقية المراتب.

التطبيق متوفر حالياً على Google Play، وهو مبني باستخدام Flutter و Supabase و Google Gemini AI.

## المميزات الرئيسية

- **ماسح الطعام بالذكاء الاصطناعي** — التقط صورة لوجبتك واحصل فوراً على تحليل غذائي كامل، وتحذيرات من المكونات الضارة، وتقييم صحي شخصي عبر Google Gemini.
- **خطط تمارين مخصصة** — برامج تمارين تتكيف تلقائياً مع بيانات المستخدم البيومترية وأسلوب حياته وأهدافه.
- **تتبع الخطوات** — تكامل مع عداد الخطوات الأصلي للجهاز مع أهداف يومية وعرض مرئي للتقدم.
- **المهام الصحية اليومية** — مهام مُلعَّبة تكافئ الاستمرارية بعملات معدنية، وترقيات في المراتب، وإنجازات.
- **إشعارات ذكية** — تذكيرات للماء والوجبات والنشاط، مُعدَّة حسب لغة المستخدم ومنطقته الزمنية.
- **خصوصية أولاً** — يتم جمع البيانات الصحية بموافقة صريحة وتُخزَّن بأمان.
- **واجهة ثلاثية اللغات** — دعم كامل للعربية (RTL)، والتركية، والإنجليزية، مع حفظ تفضيلات اللغة.
- **يعمل دون اتصال** — ذاكرة تخزين مؤقت محلية SQLite مع طابور مزامنة يتصالح مع Supabase عند عودة الاتصال.

## التقنيات المستخدمة

| الطبقة | التقنية |
|---|---|
| الإطار | Flutter (Dart 3.5+) |
| إدارة الحالة | GetX |
| الخادم / المصادقة | Supabase (PostgreSQL + Auth + Storage) |
| الذكاء الاصطناعي | Google Generative AI (Gemini) |
| التخزين المحلي | SQLite (`sqflite`)، `shared_preferences` |
| المصادقة | Google Sign-In + Supabase Auth |
| الإشعارات | `flutter_local_notifications` + `timezone` |
| الإعلانات | Google AdMob (App Open، Rewarded، Banner، Native) |
| الحساسات | `pedometer`، `camera`، `permission_handler` |
| واجهة المستخدم | `google_fonts`، `flutter_svg`، `fl_chart`، `confetti`، `shimmer` |

## البنية المعمارية

يتبع المشروع **بنية طبقية مرتكزة على الميزات (Feature-First)**:

```
lib/
├── core/           # السمات، المسارات، الربط، اللغات، الودجات المشتركة
├── data/           # المستودعات، مصادر البيانات المحلية، نماذج البيانات
├── features/       # وحدات الميزات (auth, onboarding, dashboard, profile, history, splash)
│   └── <feature>/
│       ├── controllers/
│       ├── screens/
│       └── widgets/
├── models/         # نماذج المجال (Domain Models)
├── services/       # الخدمات العامة (AI، المصادقة، الإشعارات، الإعلانات، المزامنة، قاعدة البيانات)
└── main.dart       # نقطة بدء التطبيق ودورة الحياة
```

**مبادئ التصميم:**
- مسؤولية واحدة لكل خدمة — كل خدمة تتولى اختصاصاً واحداً (مصادقة، إعلانات، إشعارات، إلخ).
- نمط المستودع (Repository) للوصول إلى البيانات — الواجهة لا تتحدث مباشرة مع الـ APIs الخارجية.
- طابور المزامنة للمرونة — عمليات الكتابة تُحفَظ محلياً وتُزامَن عند عودة الاتصال.
- مراعاة اللغة في كل شيء — النصوص، التواريخ، الأرقام، والمناطق الزمنية تحترم لغة المستخدم.

## البدء بالعمل

### المتطلبات

- Flutter SDK **3.5.0** أو أحدث
- Android Studio أو VS Code مع إضافتي Flutter و Dart
- Android SDK (الحد الأدنى API **21** / أندرويد 5.0)
- مشروع Supabase، ومفتاح Gemini API، ومعرفات AdMob (انظر أدناه)

### الإعداد

1. **استنساخ المستودع**
   ```bash
   git clone https://github.com/hasanoso151/you-app.git
   cd you-app
   ```

2. **تثبيت الاعتماديات**
   ```bash
   flutter pub get
   ```

3. **إعداد متغيرات البيئة**

   انسخ `.env.example` إلى `.env` ثم املأ بياناتك الخاصة:
   ```bash
   cp .env.example .env
   ```

   المفاتيح المطلوبة موثقة في [`.env.example`](.env.example).

4. **تشغيل التطبيق**
   ```bash
   flutter run
   ```

### بناء نسخة الإصدار

```bash
# ملف APK للأندرويد
flutter build apk --release

# حزمة App Bundle لمتجر Play
flutter build appbundle --release
```

توقيع نسخة الإصدار يتطلب keystore خاص بأندرويد. راجع توثيق Flutter حول [توقيع التطبيق](https://docs.flutter.dev/deployment/android#signing-the-app).

## اللغات

ملفات الترجمة موجودة في `lib/core/localization/`. التطبيق يدعم ثلاث لغات:

- `ar_AE` — العربية (افتراضي، RTL)
- `tr_TR` — التركية
- `en_US` — الإنجليزية

تُحفَظ لغة المستخدم في `shared_preferences` وتُحترَم عبر إعادة تشغيل التطبيق.

## الخصوصية والأمان

- جميع الأسرار (Secrets) تُحمَّل من ملف `.env` في وقت التشغيل — لا شيء مكتوب مباشرة في الكود.
- مفاتيح API ومفاتيح التوقيع وبيانات الاعتماد مستبعدة من إدارة الإصدارات عبر [`.gitignore`](.gitignore).
- البيانات الصحية مخزنة في Supabase تحت سياسات أمان على مستوى الصف (RLS) مرتبطة بالمستخدم المُصادَق عليه.
- راجع [SECURITY.md](SECURITY.md) للإبلاغ عن الثغرات.

## حالة المشروع

- **متوفر على Google Play** — الإصدار **1.2.2** (Build 22)
- التطوير النشط مستمر على قدرات الفحص بالذكاء الاصطناعي وتوسيع دعم اللغات

## الترخيص

هذا المشروع يُنشَر تحت ترخيص **خاص (Proprietary)** — جميع الحقوق محفوظة. الكود منشور لأغراض العرض والاطلاع التعليمي فقط. انظر [LICENSE](LICENSE) للاطلاع على الشروط الكاملة.

## المؤلف

طوَّره ويصونه **[@hasanoso151](https://github.com/hasanoso151)**.

للاستفسارات التجارية أو الشراكات أو طلبات الترخيص، افتح Issue أو تواصل عبر GitHub.

---

</div>

<div align="center">

**إذا أعجبك المشروع، فكِّر في إعطائه ⭐**

</div>
