# Multi-Language Support (i18n) Guide

## Overview
The TeleMedCare app now supports three languages:
- 🇬🇧 **English** (en) - Default
- 🇮🇳 **Hindi** (hi) - हिन्दी
- 🇮🇳 **Marathi** (mr) - मराठी

## Using Translations in Your Code

### Method 1: Using Context Extension (Recommended)
```dart
import '../../core/utils/localization_extension.dart';

// In your widget build method:
Text(context.tr('welcomeBack'))  // Shorthand
Text(context.l10n.translate('email'))  // Full method
```

### Method 2: Using AppLocalizations Directly
```dart
import '../../core/l10n/app_localizations.dart';

// In your widget build method:
final l10n = AppLocalizations.of(context);
Text(l10n.translate('password'))
```

### Example Screen with Translations
```dart
import 'package:flutter/material.dart';
import '../../core/utils/localization_extension.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
      ),
      body: Column(
        children: [
          Text(context.tr('hello')),
          Text(context.tr('welcomeBack')),
          ElevatedButton(
            onPressed: () {},
            child: Text(context.tr('bookAppointment')),
          ),
        ],
      ),
    );
  }
}
```

## Adding New Translations

### 1. Add to JSON Files
Update all three translation files:

**assets/l10n/en.json:**
```json
{
  "yourNewKey": "Your English Text"
}
```

**assets/l10n/hi.json:**
```json
{
  "yourNewKey": "आपका हिंदी पाठ"
}
```

**assets/l10n/mr.json:**
```json
{
  "yourNewKey": "तुमचा मराठी मजकूर"
}
```

### 2. Use in Code
```dart
Text(context.tr('yourNewKey'))
```

## Language Selection

### For Users
1. Navigate to Settings → Language
2. Or navigate to `/dashboard/language-settings`
3. Select desired language
4. App will reload with new language

### Programmatically Change Language
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/language_provider.dart';

// In a ConsumerWidget:
final languageNotifier = ref.read(languageProvider.notifier);
await languageNotifier.changeLanguage('hi');  // Switch to Hindi
await languageNotifier.changeLanguage('mr');  // Switch to Marathi
await languageNotifier.changeLanguage('en');  // Switch to English
```

## Language Selector Widget

### Use in Any Screen
```dart
import '../../shared/widgets/language_selector.dart';

// As a list (in settings)
LanguageSelector(showAsDialog: false)

// As a dialog button (in app bar)
LanguageSelector(showAsDialog: true)
```

## Available Translation Keys

### Authentication
- `welcomeBack`, `loginToContinue`, `email`, `password`, `login`
- `createAccount`, `signUp`, `dontHaveAccount`, `alreadyHaveAccount`
- `name`, `phone`, `role`, `selectRole`

### User Roles
- `patient`, `doctor`, `nurse`, `pharmacist`, `admin`

### Doctor Registration
- `doctorRegistration`, `specialization`, `experience`
- `registrationNumber`, `hospitalName`, `qualification`

### Dashboard
- `dashboard`, `patientDashboard`, `doctorDashboard`
- `home`, `services`, `pharmacy`, `records`, `profile`
- `quickActions`, `todaysVitals`, `upcomingAppointments`

### Actions
- `bookAppointment`, `aiTriage`, `findDoctors`, `emergencyCall`
- `videocall`, `manageAvailability`, `prescribe`

### Medical
- `heartRate`, `bloodPressure`, `temperature`, `oxygenLevel`
- `symptoms`, `consultationType`, `videoConsult`, `offlineVisit`
- `prescriptions`, `reports`, `medicalRecords`

### Services
- `generalMedicine`, `pediatrics`, `cardiology`, `dermatology`
- `orthopedics`, `gynecology`, `diagnosticServices`, `labTests`

### Pharmacy
- `orderMedicines`, `searchMedicines`, `prescriptionRequired`
- `inStock`, `outOfStock`, `addToCart`, `checkout`

### Common UI
- `save`, `cancel`, `delete`, `edit`, `add`, `search`, `filter`
- `loading`, `retry`, `error`, `success`, `yes`, `no`, `ok`
- `back`, `continue`, `done`, `close`, `next`

### Settings
- `settings`, `language`, `notifications`, `privacyPolicy`
- `termsConditions`, `helpSupport`, `logout`

### Error Messages
- `errorOccurred`, `tryAgain`, `noInternet`, `checkConnection`
- `loginFailed`, `invalidCredentials`, `invalidEmail`, `invalidPhone`

## Migration Guide for Existing Screens

### Before:
```dart
Text('Book Appointment')
Text('Welcome Back')
```

### After:
```dart
// Add import
import '../../core/utils/localization_extension.dart';

// Replace hardcoded strings
Text(context.tr('bookAppointment'))
Text(context.tr('welcomeBack'))
```

## Routes

Language settings is accessible at:
- Route: `/dashboard/language-settings`
- Navigation: `context.push('/dashboard/language-settings')`

## Testing Different Languages

### During Development
1. Open `lib/core/l10n/language_provider.dart`
2. Change initial locale in constructor:
```dart
LanguageNotifier(this._storage) : super(const Locale('hi', '')) {  // Hindi
// or
LanguageNotifier(this._storage) : super(const Locale('mr', '')) {  // Marathi
```

### Via UI
1. Run the app
2. Navigate to Settings → Language
3. Select language
4. App updates immediately

## Best Practices

1. ✅ Always use translation keys for user-facing text
2. ✅ Keep translation keys descriptive (e.g., `bookAppointment` not `btn1`)
3. ✅ Add all keys to all three JSON files
4. ✅ Test your screen in all three languages
5. ❌ Don't hardcode user-facing strings
6. ❌ Don't forget to update JSON files when adding new text

## Files Structure

```
assets/
  l10n/
    en.json  # English translations
    hi.json  # Hindi translations
    mr.json  # Marathi translations

lib/
  core/
    l10n/
      app_localizations.dart      # Main localization class
      language_provider.dart      # State management for language
    utils/
      localization_extension.dart # Context extension for easy access
  shared/
    widgets/
      language_selector.dart      # Language picker widget
  features/
    settings/
      presentation/
        language_settings_screen.dart  # Full settings screen
```

## Troubleshooting

### Translations not showing?
1. Check if key exists in all JSON files
2. Run `flutter pub get`
3. Restart app (not hot reload)

### Language not persisting?
- Language choice is saved in secure storage automatically

### Adding new language?
1. Create `assets/l10n/xx.json` (xx = language code)
2. Add to `AppLocalizations.supportedLocales` list
3. Update `AppLocalizationsDelegate.isSupported()`
4. Add language option in `LanguageSelector` widget
