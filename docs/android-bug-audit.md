# Audit Bug Android — Aplikasi Flutter Cuan

**Tanggal:** 2026-10-16
**Metode:** Audit statis (baca kode, tanpa menjalankan). Tidak ada kode yang diubah.
**Latar:** User melaporkan "masih banyak bug dan masih banyak fitur yang tidak fungsi" di HP Android.

---

## Ringkasan Eksekutif

| Severity | Jumlah | Tema |
|----------|--------|------|
| High | 2 | Fitur terlihat jalan tapi tidak menghasilkan apa-apa; error tidak pernah ditampilkan |
| Medium | 4 | Toggle/fitur placebo; fitur hanya baca; tidak ada input manual |
| Low | 3 | Keterbatasan yang diketahui / by-design tapi menyesatkan |

**Kabar baik:** Semua endpoint API yang dipanggil app ADA di backend dan field
request/response cocok (diverifikasi satu per satu melawan
`core/src/modules/*/​*.controller.ts` dan `*.dto.ts`). Tidak ditemukan API
mismatch. AndroidManifest juga sudah benar (INTERNET, USE_BIOMETRIC,
RECORD_AUDIO, POST_NOTIFICATIONS).

---

## [HIGH] 1. "Backup data" tidak menyimpan / membagikan apa pun

**File:** `lib/features/settings/presentation/settings_page.dart:410-432`

```dart
Future<void> _backupData(BuildContext context) async {
  ...
  final data = await api.backupExport();   // JSON di-download...
  final txCount = (data['transactions'] as List?)?.length ?? 0;
  // ...lalu DIBUANG. Hanya tampil snackbar:
  SnackBar(content: Text('Backup siap: $txCount transaksi diekspor.'))
}
```

**Kenapa ini bikin fitur tidak fungsi:** User menekan "Backup data", melihat
pesan "Backup siap", dan percaya datanya aman — padahal tidak ada file yang
disimpan ke storage dan tidak ada share sheet. Kalau HP hilang, data tetap
hilang. Ini fitur placebo yang berbahaya karena memberi rasa aman palsu.

**Perbaikan yang dibutuhkan:** Simpan JSON ke file (path_provider +
share_plus / file_picker) atau tampilkan share sheet Android.

---

## [HIGH] 2. Tidak ada halaman yang menampilkan error state

**File:** Semua presentation di bawah ini (0 referensi ke `*.error`):
- `lib/features/home/presentation/home_page.dart:56`
- `lib/features/activity/presentation/activity_page.dart:77`
- `lib/features/budgets/presentation/budgets_page.dart`
- `lib/features/accounts/presentation/accounts_page.dart`
- `lib/features/recurring/presentation/recurring_page.dart`
- `lib/features/savings/presentation/savings_page.dart`
- `lib/features/debts/presentation/debts_page.dart`

Pola yang dipakai cubit sudah benar — contoh `home_cubit.dart:26`:

```dart
} catch (_) {
  emit(state.copyWith(status: HomeStatus.error));  // status error DIEMIT
}
```

Tapi halaman hanya mengecek:

```dart
if (state.status == HomeStatus.loading || state.status == HomeStatus.initial) {
  return const Center(child: CircularProgressIndicator(...));
}
// status == error JATUH KE SINI → render dengan data kosong
```

**Kenapa ini bikin fitur tidak fungsi (dari sudut pandang user):** Saat
jaringan gagal, server 500, atau sesi kedaluwarsa (401), user TIDAK melihat
pesan error. Yang terlihat: dashboard kosong, atau "Tidak ada transaksi."
padahal datanya ada. User mengira aplikasinya rusak / datanya hilang, dan
tidak ada tombol "Coba lagi" (satu-satunya jalan keluar adalah pull-to-refresh
yang tidak jelas). Ini kemungkinan besar sumber keluhan "banyak yang tidak
fungsi" — sesungguhnya jaringannya yang gagal, tapi UI-nya berbohong.

**Perbaikan yang dibutuhkan:** Setiap halaman harus menangani `*.error`:
tampilkan pesan error + tombol "Coba lagi" yang memanggil `cubit.load()`.

---

## [MEDIUM] 3. Toggle "Notifikasi push" tidak mengendalikan apa pun

**File:**
- `lib/features/settings/bloc/settings_cubit.dart:28-29`
- `lib/features/settings/presentation/settings_page.dart:259-267`

```dart
void toggleNotifications(bool value) =>
    emit(state.copyWith(notificationsEnabled: value));  // hanya state lokal
```

**Kenapa ini masalah:** Toggle tidak di-persist (hilang saat restart app) dan
tidak memanggil apa pun — FCM diinisialisasi sekali di
`NotificationService.init()` terlepas dari toggle ini. User mengira ia
mengatur notifikasi, padahal tidak ada efeknya. Ditambah lagi FCM memang belum
dikonfigurasi (`google-services.json` belum ada — deferred), jadi subtitle
"Info budget & pengingat transaksi" menjanjikan sesuatu yang tidak bisa
terjadi.

**Perbaikan yang dibutuhkan:** Hubungkan toggle ke `NotificationService`
(persist preferensi; batalkan/daftarkan token), atau sembunyikan sampai FCM
siap.

---

## [MEDIUM] 4. Halaman Accounts hanya-baca (tidak bisa tambah/hapus akun)

**File:** `lib/features/accounts/data/accounts_repository.dart` (hanya ada
`list()`); `lib/features/accounts/presentation/accounts_page.dart` (tidak ada
dialog tambah, tidak ada aksi hapus)

Backend menyediakan `POST /api/financial-accounts`,
`PATCH /api/financial-accounts/:id`, `DELETE /api/financial-accounts/:id`,
tapi tidak satu pun dipanggil dari aplikasi mobile.

**Kenapa ini masalah:** User yang hanya pakai HP tidak bisa menambah akun
baru (mis. buka e-wallet baru) atau menghapus akun — harus buka web. Untuk
aplikasi pencatat keuangan, ini fitur inti yang hilang di mobile.

---

## [MEDIUM] 5. Tidak ada input transaksi manual di mobile

**File:** `lib/core/api/cuan_api.dart:189` (`createTransaction` — tidak pernah
dipanggil di mana pun; verified via grep)

Satu-satunya cara menambah transaksi di HP adalah lewat AI chat. Tidak ada
form "tambah transaksi" seperti di web.

**Kenapa ini masalah:** Kalau AI sedang error / kuota habis / user ingin input
cepat tanpa mengetik kalimat, tidak ada jalan lain. Fungsi `createTransaction`
sudah ada dan field-nya cocok dengan backend (`type`, `amount` numeric,
`categoryId`, `accountId`, `description`, `date`) — tinggal belum ada UI yang
memakainya.

---

## [MEDIUM] 6. Tombol mic diam saat speech recognition tidak tersedia

**File:** `lib/features/assistant/presentation/assistant_page.dart:44-53`

```dart
final available = await _speech.initialize(...);
if (!available) return;  // diam saja — user menekan mic, tidak terjadi apa-apa
```

**Kenapa ini masalah:** Jika permission mikrofon ditolak atau device tidak
mendukung, tombol mic tidak memberi feedback apa pun. User mengira tombolnya
rusak.

**Perbaikan yang dibutuhkan:** Tampilkan snackbar ("Izin mikrofon ditolak" /
"Perangkat tidak mendukung") saat `available == false`.

---

## [LOW] 7. Split bill hanya kalkulator lokal

**File:** `lib/features/splitbill/` (tidak ada satu pun pemanggilan API)

Hasil patungan tidak disimpan sebagai transaksi dan tidak tersinkron ke
backend. Kemungkinan by-design (kalkulator), tapi user yang berharap
"patungan tercatat sebagai pengeluaran" akan kecewa.

---

## [LOW] 8. Health score card hilang diam-diam saat error

**File:** `lib/features/home/bloc/health_score_cubit.dart:31-33`

```dart
} catch (_) {
  // Silent — card just won't show.
  emit(state.copyWith(loading: false));
}
```

Disengaja (komentar jelas), tapi berarti user tidak tahu kenapa kartunya tidak
muncul. Setelah temuan #2 diperbaiki, ini sebaiknya ikut menampilkan pesan
ringan.

---

## [LOW] 9. FCM belum terkonfigurasi (diketahui, ditunda)

`google-services.json` tidak ada di `android/app/` (sesuai keputusan user:
"fcm nanti saja"). `NotificationService` sudah graceful (no-op). Bukan bug,
tapi dicatat karena subtitle "Notifikasi push" di settings menjanjikan fitur
yang belum bisa jalan.

---

## Verifikasi yang dilakukan (tidak ada masalah)

1. **Semua 27 endpoint** yang dipanggil app terkonfirmasi ada di backend
   (`/api/transactions`, `/stats`, `/api/budgets`, `/api/recurring`,
   `/api/recurring/generate`, `/api/savings-goals`, `/add-funds`,
   `/api/debts`, `/pay`, `/api/fcm-tokens`, `/api/insights/health-score`,
   `/api/backup/export`, `/api/chat/`, `/api/financial-accounts`,
   `/api/categories`, `/auth/api/*`).
2. **Field payload cocok:** recurring (`amount` string, `frequency` enum),
   debts (`type: hutang|piutang`), savings (`targetAmount` string), budgets
   (`amount` string via konversi double→string), chat
   (`message/locale/timezone/history`), month format `YYYY-MM` (7 char sesuai
   DTO).
3. **AndroidManifest:** permission lengkap untuk fitur yang ada. Fix biometric
   (`FlutterFragmentActivity`) sudah di-commit terpisah.
4. Tidak ada `onPressed: () {}` kosong; tidak ada TODO/FIXME yang menggantung.

---

## Rekomendasi urutan perbaikan (dampak bagi user)

1. Temuan #2 (error state) — kemungkinan penyebab utama keluhan "banyak yang
   tidak fungsi".
2. Temuan #1 (backup) — memberi rasa aman palsu; berbahaya.
3. Temuan #5 (input manual) — menutup celah fungsional terbesar di mobile.
4. Temuan #4 (kelola akun) + #3 (toggle notifikasi) + #6 (mic feedback).
