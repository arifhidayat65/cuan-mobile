# Payment Integration — API Documentation Discovery Report

**Tanggal pengecekan:** 2026-10-15
**Tujuan:** Verifikasi dokumentasi resmi DANA & Xendit sebelum implementasi integrasi pembayaran di aplikasi Cuan.

---

## 1. URL Dokumentasi yang Diperiksa

| # | Sumber | URL | Status |
|---|--------|-----|--------|
| 1 | DANA API Docs (main) | https://dashboard.dana.id/api-docs-v2/ | ✅ Terbuka |
| 2 | DANA Merchant Onboarding | https://dashboard.dana.id/api-docs-v2/guide/getting-started/getting-started-onboarding | ❌ 500 (tidak bisa diakses) |
| 3 | DANA Integration Overview | https://dashboard.dana.id/api-docs-v2/guide/getting-started/integration-overview | ✅ Terbuka |
| 4 | DANA Create Order (Hosted) | https://dashboard.dana.id/api-docs-v2/api/payment-gateway/create-order-hosted | ✅ Terbuka |
| 5 | DANA Create Order (Custom) | https://dashboard.dana.id/api-docs-v2/api/payment-gateway/create-order-custom | ⏳ Belum dibuka |
| 6 | DANA Query Payment | https://dashboard.dana.id/api-docs-v2/api/payment-gateway/optional-api/query-payment | ❌ 500 (tidak bisa diakses) |
| 7 | DANA PG Overview | https://dashboard.dana.id/api-docs-v2/api/payment-gateway/overview | ✅ Terbuka |
| 8 | Xendit E-Wallet | https://docs.xendit.co/id/ewallet | ✅ Terbuka |
| 9 | Xendit API Reference | https://developers.xendit.co/api-reference/id/ | ✅ Terbuka |

---

## 2. DANA — Gapura Payment Gateway (Terverifikasi)

### Produk
DANA "Gapura Payment Gateway" — solusi payment gateway dengan dua opsi:
- **Hosted Checkout**: DANA sediakan halaman checkout (redirect via `webRedirectUrl`)
- **Custom API**: akses ke core payment API DANA

### Endpoint Terverifikasi
| Operasi | Method & Path |
|---------|---------------|
| Create Order (Hosted) | `POST /payment-gateway/v1.0/debit/payment-host-to-host.htm` |
| Finish Notify (webhook) | DANA → merchant (payment status notification) |

- **API Type:** SNAP API (Standar Nasional Open API Pembayaran, Bank Indonesia)
- **SNAP Service Code:** 54
- **Expected timeout:** 8 detik
- **Content-Type / Accept:** application/json

### Authentication & Signature (SNAP)
Header wajib:
| Header | Keterangan |
|--------|-----------|
| `X-TIMESTAMP` | Format `2024-12-23T09:10:11+07:00` |
| `X-SIGNATURE` | Asymmetric signature (RSA private key merchant) |
| `X-PARTNER-ID` | ID partner dari dashboard DANA |
| `X-EXTERNAL-ID` | Numeric string unik per request |
| `CHANNEL-ID` | Contoh: `95221` |

Signature mengikuti standar SNAP BI (asymmetric SHA256withRSA, JWS detached).

### Request Fields (Create Order)
| Field | Wajib | Keterangan |
|-------|-------|-----------|
| `partnerReferenceNo` | Ya | Nomor referensi unik merchant |
| `merchantId` | Ya | ID merchant DANA |
| `amount.value` | Ya | String decimal, contoh `"15000.00"` |
| `amount.currency` | Ya | `"IDR"` |
| `validUpTo` | Ya | ISO8601; di sandbox ≤ 30 menit dari request |
| `urlParams[]` | Ya | `PAY_RETURN` (redirect) + `NOTIFICATION` (webhook); `isDeeplink: Y` |
| `additionalInfo.order.orderTitle` | Ya | Judul order |
| `additionalInfo.order.scenario` | Ya | `"REDIRECT"` |
| `additionalInfo.mcc` | Tidak | Merchant category code |
| `additionalInfo.envInfo` | Tidak | `sourcePlatform`, `terminalType` |

### Response
- Sukses: `responseCode: "2005400"`, `responseMessage: "Successful"`, `referenceNo`, `partnerReferenceNo`, `additionalInfo.paymentCode` (untuk VA/QRIS)
- Hosted checkout: response berisi `webRedirectUrl` untuk redirect user

### Idempotency
Dikontrol oleh **Idempotent Key = merchantId + partnerReferenceNo**:
- Key sudah ada + info konsisten → `2005400` (sukses)
- Key sudah ada + info tidak konsisten → `4045418` (inconsistent request)

### Error Codes (penting)
| Code | Arti |
|------|------|
| 2005400 | Sukses |
| 4005400/401/402 | Bad request / invalid field |
| 4015400 | Invalid signature |
| 4035402 | Melebihi limit nominal |
| 4045408 | Merchant tidak valid |
| 4045418 | Inconsistent request (idempotency) |
| 4295400 | Too many requests → tandai Pending, retry |
| 5005400/501 | Server error → tandai Pending, retry maks 3x |

### Alur Pembayaran (Hosted Checkout)
1. User checkout di aplikasi merchant
2. Backend merchant buat order internal
3. Backend hit Create Order API DANA
4. DANA balas dengan `webRedirectUrl`
5. User di-redirect ke halaman checkout DANA, pilih metode bayar
6. DANA proses pembayaran, tampilkan hasil ke user
7. DANA kirim **Finish Notify webhook** ke merchant
8. DANA redirect user ke merchant URL

### Merchant Registration
1. Akses developer dashboard → Start Integration
2. Setup webhook URLs
3. Ambil developer credentials (sandbox)
4. Selesaikan Integration Checklist (scenario testing)
5. Tanda tangan UAT Sign-Off Report
6. Apply for Production (production key + endpoint whitelist)

### Yang Belum Terverifikasi (DANA)
- ❌ Query Payment endpoint (halaman 500)
- ❌ Detail Custom Checkout Create Order (belum dibuka)
- ❌ Sandbox vs production base URL eksplisit (tidak tercantum di halaman yang terbuka)
- ❌ OpenAPI/Swagger machine-readable spec (tidak ditemukan)
- ❌ Official SDK (dokumen menyebut "DANA's Libraries" tapi link tidak terverifikasi)

---

## 3. Xendit — E-Wallet (Terverifikasi)

### Cakupan
Satu integrasi untuk semua e-wallet:
- **Indonesia:** OVO, DANA, LinkAja, ShopeePay (ID), AstraPay, Jenius Pay
- **Filipina:** Maya, GrabPay, GCash, ShopeePay (PH)

Juga tersedia via XenInvoice (hosted) atau plugin (Shopify, WooCommerce, Magento).

### Authentication
- **Method:** HTTP Basic Auth
- **Username:** Secret API key, **password:** kosong (dengan colon di akhir)
- Format: `Base64("{secret_api_key}:")` di header `Authorization`
- **Hanya HTTPS**; request test tidak menyentuh jaringan bank (gratis)

### API Reference
- https://developers.xendit.co/api-reference/ — REST, JSON, HTTP status codes standar
- Detail endpoint e-wallet spesifik (create charge, dll.) ada di `https://developers.xendit.co/api-reference/#ewallets` (belum dibuka detailnya)

### Yang Belum Terverifikasi (Xendit)
- ⏳ Detail endpoint e-wallet (create/get charge, callback)
- ⏳ Webhook verification (callback token)
- ⏳ Sandbox base URL eksplisit

---

## 4. Perbandingan & Rekomendasi

| Aspek | DANA Direct | Xendit |
|-------|-------------|--------|
| Cakupan | Hanya DANA (+ metode lain via Gapura) | Semua e-wallet ID dalam 1 API |
| Kompleksitas auth | Tinggi (SNAP RSA signature) | Rendah (Basic Auth API key) |
| Onboarding | Berat (UAT, sign-off, BI compliance) | Ringan (dashboard signup) |
| Dokumentasi | Sebagian halaman 500 | Lengkap & stabil |
| Cocok untuk | Merchant besar, volume tinggi | MVP / startup, multi-wallet |

**Rekomendasi: Xendit** untuk aplikasi Cuan karena:
1. Auth sederhana (API key vs RSA signature SNAP)
2. Satu integrasi = semua e-wallet (DANA, OVO, GoPay via Xendit, dll.)
3. Onboarding jauh lebih ringan
4. Dokumentasi stabil dan terverifikasi

DANA direct hanya direkomendasikan jika ada kebutuhan spesifik (misal fee lebih rendah di volume besar) dan tim siap menjalani proses UAT.

---

## 5. Rencana Implementasi (Butuh Persetujuan)

**Fase 1 — Discovery lanjutan (belum ada kode):**
- [ ] Buka detail Xendit e-wallet API reference (endpoint create charge, callback)
- [ ] Verifikasi webhook/callback verification Xendit

**Fase 2 — Backend (butuh API key Xendit dari Arif):**
- [ ] Modul `payment/` di `core/src`: create e-wallet charge, query status, webhook handler
- [ ] Env vars: `XENDIT_API_KEY`, `XENDIT_WEBHOOK_TOKEN`, `XENDIT_BASE_URL`
- [ ] Tabel `payments` (id, userId, externalId, amount, wallet, status, timestamps)
- [ ] Migrasi D1 + test + redeploy

**Fase 3 — Flutter:**
- [ ] Layar "Top Up" / bayar via e-wallet (pilih wallet → redirect/deeplink → poll status)
- [ ] Riwayat pembayaran

**Yang TIDAK akan diubah:** semua fitur existing (auth, transaksi, AI chat, budget, dsb.)

---

## 6. Status & Pertanyaan Terbuka

- ✅ Dokumentasi DANA parsial terverifikasi (4/7 halaman)
- ✅ Dokumentasi Xendit terverifikasi (2/2 halaman)
- ❓ **Butuh dari Arif:** akun Xendit + secret API key (test mode) untuk mulai implementasi
- ❓ Apakah Cuan butuh **terima pembayaran** (top-up) atau **kirim pembayaran** (disbursement)?
- ❓ E-wallet mana yang prioritas? (semua via Xendit, atau DANA saja?)

**Belum ada kode yang ditulis. Menunggu persetujuan rencana + API key sebelum lanjut ke implementasi.**
