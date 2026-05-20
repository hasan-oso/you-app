# Translation Keys to Add to languages.dart

Add these keys to the respective language sections in `lib/core/localization/languages.dart`:

## English (en_US):
```dart
// Add to 'en_US' map:
...privacyTranslationsEN,  // Import from privacy_translations.dart

// Additional keys needed:
'privacy_security_title': 'Privacy & Security',
'privacy_policy_subtitle': 'View our privacy policy and data practices',
```

## Arabic (ar_SA):
```dart
// Add to 'ar_SA' map:
...privacyTranslationsAR,  // Import from privacy_translations.dart

// Additional keys needed:
'privacy_security_title': 'الخصوصية والأمان',
'privacy_policy_subtitle': 'اطلع على سياسة الخصوصية وممارسات البيانات',
```

## Turkish (tr_TR):
```dart
// Add to 'tr_TR' map:
...privacyTranslationsTR,  // Import from privacy_translations.dart

// Additional keys needed:
'privacy_security_title': 'Gizlilik ve Güvenlik',
'privacy_policy_subtitle': 'Gizlilik politikamızı ve veri uygulamalarımızı görüntüleyin',
```

## Import Statement:
Add at the top of languages.dart:
```dart
import 'privacy_translations.dart';
```

## Full Integration Example:

```dart
import 'package:get/get.dart';
import 'privacy_translations.dart';  // Add this import

class Languages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // ... existing keys ...
      
      // Privacy & Security
      ...privacyTranslationsEN,
      'privacy_security_title': 'Privacy & Security',
      'privacy_policy_subtitle': 'View our privacy policy and data practices',
      
      // ... rest of keys ...
    },
    
    'ar_SA': {
      // ... existing keys ...
      
      // Privacy & Security
      ...privacyTranslationsAR,
      'privacy_security_title': 'الخصوصية والأمان',
      'privacy_policy_subtitle': 'اطلع على سياسة الخصوصية وممارسات البيانات',
      
      // ... rest of keys ...
    },
    
    'tr_TR': {
      // ... existing keys ...
      
      // Privacy & Security
      ...privacyTranslationsTR,
      'privacy_security_title': 'Gizlilik ve Güvenlik',
      'privacy_policy_subtitle': 'Gizlilik politikamızı ve veri uygulamalarımızı görüntüleyin',
      
      // ... rest of keys ...
    },
  };
}
```

Note: The spread operator `...` will merge all privacy translations into the main language maps.
