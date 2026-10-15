# ANDROID .APK DOSYASINI DERLEME VE ALMA REHBERİ

Bu proje hazır bir Flutter Android projesidir. .apk dosyasını almanın 3 kolay yolu vardır:

---

### YÖNTEM 1: GITHUB ACTIONS İLE BULUTTA 2 DAKİKADA APK ALMA (SIFIR KURULUM - EN KOLAY)
1. GitHub hesabınızda yeni bir boş repo açın (Örn: `vardiya-pdks`).
2. Bu ZIP dosyasının içindekileri repoya yükleyin (Upload files).
3. Repodaki **Actions** sekmesine gidin.
4. `.github/workflows/build_apk.yml` otomatik olarak çalışacak ve 2 dakika içinde **app-release.apk** dosyasını derleyecektir.
5. "Artifacts" başlığı altından doğrudan telefonunuza indirip kurabilirsiniz!

---

### YÖNTEM 2: KENDİ BİLGİSAYARINIZDA TEK KOMUTLA APK ALMA
Bilgisayarınızda Flutter kuruluysa terminalde şu komutu çalıştırın:

```bash
# Bağımlılıkları yükle
flutter pub get

# Android APK'sını derle
flutter build apk --release
```

Derlenen .apk dosyası şu konumda hazır olacaktır:
👉 `build/app/outputs/flutter-apk/app-release.apk`

Bu dosyayı WhatsApp, Telegram veya USB kablosuyla telefonunuza atıp üzerine tıklayarak hemen kurabilirsiniz.

---

### YÖNTEM 3: GOOGLE BUBBLEWRAP (TWA) İLE 60 SANİYEDE APK OLUŞTURMA
```bash
npx @bubblewrap/cli init --manifest=https://[UYGULAMA-ADRESINIZ]/manifest.json
npx @bubblewrap/cli build
```
