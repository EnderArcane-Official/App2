# UserLooperGen — Flutter App

Web versiyonunun (WebView APK) gerçek native Flutter karşılığı.

## Proje Yapısı

```
lib/
  main.dart                  → App + bottom nav + Home + auth akışı
  theme.dart                 → Web versiyonuyla aynı renkler
  services/
    supabase_service.dart    → Supabase auth + db + storage
  models/
    pad_model.dart           → Pad veri modeli
  screens/
    pad_screen.dart          → 4x4 pad grid, ses çalma, timer
    profile_screen.dart      → Auth + Profil
    library_screen.dart      → Loop kütüphanesi (Supabase)
.github/
  workflows/
    build.yml                → GitHub Actions — otomatik APK
```

## APK Yapmak (GitHub Actions)

1. GitHub'da yeni repo oluştur
2. Bu klasörün içindekileri repoyu yükle
3. Actions sekmesine git → build tamamlanınca APK indir

## Manuel Kurulum

```bash
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## Supabase
```
URL: https://murolvpildiiexpemlyb.supabase.co
```
Web versiyonuyla aynı veritabanı.

## OAuth Deep Link (Zorunlu)
AndroidManifest.xml içine ekle:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.enderarcane.userloopergen" android:host="auth-callback" />
</intent-filter>
```
Supabase Dashboard → Auth → URL Config'e ekle:
`io.enderarcane.userloopergen://auth-callback`

## Tamamlanan Ekranlar
- ✅ Home ekranı
- ✅ Pad ekranı (4x4, ses yükleme, loop çalma, 3dk timer)
- ✅ Auth (Google / Discord / GitHub / Email)
- ✅ Profil (avatar, username, rol rozeti, edit)
- ✅ Library (Supabase'den loop listesi, kategori, arama, yükleme)
