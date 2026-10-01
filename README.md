# 🧪 ITLG Mobile — Sistem Praktikum & Laboratorium Terpadu

Aplikasi mobile Flutter untuk manajemen praktikum laboratorium komputer dengan dukungan **4 Role Pengguna** yang terintegrasi dalam satu sistem.

---

## 👥 Anggota Kelompok

| No | Nama | NIM |
|:---:|---|:---:|
| 1 | Abbil Rizki Abdillah | 241402033 |
| 2 | Daniele Christian Hasiholland Siahaan | 241402060 |
| 3 | Reagan Brian Siahaan | 241402099 |
| 4 | Andre Al Farizi Sebayang | 241402105 |
| 5 | Yeremia Nicholas Purba | 241402140 |

---

## 👥 User Requirements per Role

### 1. 🎓 Praktikan (Mahasiswa)

| Fitur | Deskripsi |
|---|---|
| **Akses Jadwal & Modul** | Pengguna dapat melihat jadwal praktikum minggu berjalan dan mengunduh modul atau bahan ajar. |
| **Presensi Anti-Kecurangan** | Pengguna dapat melakukan pemindaian QR Code dinamis menggunakan kamera di dalam aplikasi untuk mencatatkan kehadiran yang divalidasi berdasarkan sesi aktif. |
| **Submission Tugas** | Pengguna dapat mengunggah file tugas praktikum (seperti laporan PDF, script query SQL, atau tautan repositori kode) ke cloud storage secara langsung. |
| **Transparansi Nilai** | Pengguna dapat memantau akumulasi nilai harian beserta catatan evaluasi (feedback) dari asisten. |

---

### 2. 🖥️ Asisten Laboratorium (Aslab)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Sesi & QR Dinamis** | Pengguna dapat mengaktifkan sesi kelas dan menampilkan QR Code presensi di layar yang akan melakukan auto-refresh setiap 15 detik. |
| **Evaluasi & Grading** | Pengguna dapat mengunduh tugas yang dikumpulkan praktikan, memasukkan nilai berdasarkan rubrik penilaian (misalnya kebenaran relasi database atau eksekusi query), dan memberikan feedback teks. |
| **Koordinasi Shift Jaga** | Pengguna dapat melihat kalender jadwal tugasnya dan mengajukan permintaan tukar shift (swap request) dengan asisten lain melalui notifikasi sistem. |
| **Issue Ticketing** | Pengguna dapat membuat laporan instan jika menemukan PC atau perangkat lunak (seperti proyektor, ac, koneksi jaringan) yang bermasalah saat membimbing praktikum. |

---

### 3. 🔧 Laboran (Pengawas)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Presensi Asisten** | Pengguna memiliki wewenang untuk men-generate akses absensi kehadiran bagi para Aslab yang bertugas pada hari tersebut dan memantau rekapitulasi kedisiplinan asisten. |
| **Live Monitoring** | Pengguna dapat mengakses dashboard real-time untuk memantau lab mana yang sedang digunakan, memverifikasi identitas asisten yang sedang bertugas (on-duty), dan rasio kehadiran mahasiswa. |
| **Manajemen Perbaikan (Ticketing System)** | Pengguna menerima laporan langsung dari Aslab terkait detail kerusakan di dalam lab dan dapat memperbarui status penanganan perangkat (Reported, In Progress, Resolved). |
| **Approval Ruangan** | Pengguna memegang otoritas penuh untuk menyetujui atau menolak request peminjaman ruangan untuk jadwal kelas atau praktikum pengganti. |
| **Data Inventaris** | Pengguna dapat mengelola daftar meja, spesifikasi PC, dan memastikan kelengkapan software basis data atau tools pengembangan lainnya di masing-masing laboratorium sudah siap pakai. |

---

### 4. 👨‍🏫 Dosen Pengampu

| Fitur | Deskripsi |
|---|---|
| **Dashboard Metrik** | Pengguna dapat melihat ringkasan statistik tingkat kehadiran mahasiswa dan rata-rata performa kelas di seluruh grup praktikum yang diampunya. |
| **Validasi Rekapitulasi Akhir** | Pengguna dapat meninjau dan memvalidasi akumulasi nilai akhir dari seluruh asisten sebelum disinkronisasi dengan portal akademik kampus. |
| **Generate Laporan** | Pengguna dapat mengunduh rekap akhir pelaksanaan praktikum dan pelaporan nilai dalam format spreadsheet atau PDF dengan satu kali klik. |

