# Setup Firebase buat Push Notification 🔔

Backend + aplikasi udah siap nerima push notification. Yang belum: project Firebase-nya. Ikutin langkah ini (sekitar 10 menit):

## 1. Bikin project Firebase
- Buka https://console.firebase.google.com → **Add project**
- Nama bebas, misal `cuan-app` → lanjutin sampai jadi (Google Analytics boleh dimatiin)

## 2. Daftarin aplikasi Android
- Di dashboard project → klik icon Android 🤖 → **Add app**
- **Android package name:** `com.cuan.app` (harus persis!)
- App nickname: `Cuan` → Register app
- **Download `google-services.json`**
- Taruh file-nya di: `cuan-mobile/android/app/google-services.json`
  (sejajar sama `build.gradle.kts`, BUKAN di dalam `src/`)

## 3. Bikin Service Account buat backend
- Project Settings (⚙️) → tab **Service accounts**
- Klik **Generate new private key** → download file JSON-nya
- Simpen baik-baik, jangan dishare ke siapa pun

## 4. Set secret di backend (Cloudflare Workers)
Jalankan dari folder `cuan/core`:

```bash
# Project ID Firebase (lihat di Project Settings → General)
npx wrangler secret put FCM_PROJECT_ID
# → isi dengan project ID, misal: cuan-app-12345

# Isi service account JSON (paste SELURUH isi file JSON)
npx wrangler secret put FCM_SERVICE_ACCOUNT_JSON
# → paste isi file JSON dari langkah 3
```

> `FCM_SERVICE_ACCOUNT_JSON` harus jadi **secret**, jangan taruh di `wrangler.toml`.

## 5. Deploy backend + rebuild APK
```bash
cd cuan/core && npx wrangler deploy   # backend bawa endpoint /api/fcm-tokens
# terus rebuild APK seperti biasa
```

## Cara ngetes
1. Install APK baru di HP, login/daftar
2. Izinkan notifikasi waktu diminta (Android 13+)
3. Bikin budget, terus catat pengeluaran sampai ≥90% budget → HP harusnya dapet notif "Budget hampir habis" 🎉

## Catatan
- Cloud Messaging API aktif otomatis di project baru, nggak perlu enable manual.
- Kalau `google-services.json` belum dipasang, aplikasi tetap jalan normal — cuma push-nya aja yang nonaktif.
