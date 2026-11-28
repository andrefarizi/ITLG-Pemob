# 🧪 ITLG Mobile — Sistem  Manajemen Informasi Praktikum & Laboratorium

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

## 🛠️ Tech Stack

| Kategori | Teknologi | Kegunaan di Proyek |
|---|---|---|
| **Mobile Framework & Bahasa** | **Flutter** & **Dart** (`SDK ^3.9.2`) | Membangun antarmuka dan logika aplikasi mobile lintas 4 role (Praktikan, Aslab, Laboran, Dosen) menggunakan *state management* bawaan (`ChangeNotifier` & `ListenableBuilder`). |
| **Native Android Bridge** | **Kotlin**, **Gradle (JVM 17)** & **MethodChannel** | Integrasi fitur native perangkat Android seperti pemilih berkas/galeri (*Storage Access Framework*), penyimpanan file unduhan laporan, dan sinkronisasi jadwal ke kalender perangkat. |
| **Backend & Database** | **Supabase** (`supabase_flutter ^2.18.3`) — **PostgreSQL** | Database relasional utama beserta *Row Level Security (RLS)* dan fungsi *RPC PL/pgSQL* (penguncian transaksi meja anti-ganda, verifikasi & reset kata sandi). |
| **Autentikasi & Real-time** | **Supabase Auth** & **Supabase Realtime** | Manajemen login/logout sesi 4 role berbasis NIM/NIP serta sinkronisasi data dan notifikasi lintas role secara langsung (*real-time*). |
| **Cloud File Storage** | **Supabase Storage** (`itlg-uploads`) | Penyimpanan berkas unggahan nyata untuk foto profil, pengumpulan tugas, lampiran izin, dan foto bukti laporan kerusakan. |
| **Peta & Geofencing GPS** | **Google Maps Flutter** (`^2.9.0`) & **Geolocator** (`^13.0.2`) | Menampilkan peta lokasi laboratorium dan memvalidasi jarak koordinat GPS praktikan terhadap radius lab saat presensi. |
| **QR Code & Kamera** | **QR Flutter** (`^4.1.0`) & **Mobile Scanner** (`^7.5.0`) | Menghasilkan dan memindai QR Code dinamis untuk presensi praktikan maupun *check-in* mengajar asisten (rotasi 60 detik). |
| **Layanan Email** | **Mailer** (`^6.2.0`) | Pengiriman email SMTP untuk kode verifikasi OTP pada fitur lupa kata sandi. |
| **Maskot 3D Interaktif** | **WebView Flutter** (`^4.10.0`) & **Three.js** | Merender tampilan dan animasi maskot 3D interaktif **Gyro** pada halaman **Tanya Gyro**. |
| **Desain & Tipografi** | **Figma Design System** & **Font Montserrat** | Referensi antarmuka konsisten (warna, bayangan, komponen, ikon) serta font kustom **Montserrat** di seluruh halaman aplikasi. |

---

## 👥 User Requirements per Role

### 1. 🎓 Praktikan (Mahasiswa)

| Fitur | Deskripsi |
|---|---|
| **Akses Jadwal, Pengumuman & Modul** | Pengguna dapat melihat jadwal praktikum mingguan (termasuk pembagian sesi kelas C1/C2 dan sinkronisasi ke kalender perangkat), membaca pengumuman asisten, serta melihat dan mengunduh materi atau modul pada setiap pertemuan. |
| **Presensi Anti-Kecurangan (QR, GPS & Tanda Tangan)** | Pengguna dapat melakukan presensi kehadiran melalui pemindaian QR Code dinamis menggunakan kamera atau tombol hadir berbasis validasi lokasi GPS sesuai metode yang diaktifkan asisten dan radius lab sesi aktif, dilengkapi verifikasi tanda tangan digital. |
| **Riwayat Absensi & Pengajuan Izin** | Pengguna dapat memantau rekap persentase dan detail kehadiran tiap praktikum serta mengajukan izin/sakit (dengan lampiran opsional) maupun laporan kendala QR (menyertakan keterangan, nomor meja, dan foto bukti opsional) untuk ditinjau asisten. |
| **Pemilihan Meja Lab & Laporan Kerusakan (`LK-`)** | Pengguna dapat memilih meja/PC yang tersedia pada denah 6 baris susunan 3 \| 2 (30 meja per lab) dengan penguncian anti-ganda, berpindah meja, mengakhiri pemakaian (*check-out*), melihat kartu pintasan meja aktif di beranda, serta melaporkan kerusakan perangkat yang otomatis terhubung ke meja/PC aktif lengkap dengan foto bukti dan riwayat status penanganan Laboran. |
| **Submission Tugas & Kuis** | Pengguna dapat mengumpulkan, mengganti, menghapus berkas, atau membatalkan pengumpulan tugas sebelum tenggat (berkas, tautan repositori, dan catatan untuk asisten), serta mengerjakan kuis satu kali (*idempotent*) dan melihat skor beserta rincian pembahasannya. |
| **Transparansi Nilai, Sanggah Nilai & Penilaian Asisten** | Pengguna dapat memantau akumulasi dan rincian nilai beserta feedback asisten, mengajukan sanggahan nilai (alasan, nilai saat ini, usulan nilai, dan bukti lampiran) untuk direkomendasikan asisten dan diputuskan dosen, serta memberikan penilaian kinerja asisten. |
| **Notifikasi, Profil, Keamanan Akun & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi pembaruan praktikum (dengan badge belum dibaca, pengelompokan waktu, dan tautan ke mata kuliah/pertemuan terkait), memperbarui nama/nomor HP serta foto profil (menampilkan inisial bila kosong), mengubah kata sandi, dan menggunakan asisten AI **Tanya Gyro**. |

---

### 2. 🖥️ Asisten Laboratorium (Aslab)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Sesi & Presensi Praktikan** | Pengguna dapat membuka sesi presensi kelas dengan pengaturan metode aktif (QR Code dinamis & tombol hadir berbasis lokasi GPS), memantau daftar lengkap seluruh praktikan pada sesi aktif, melihat bukti presensi/tanda tangan, mengubah status kehadiran secara manual, serta otomatis melepaskan meja aktif saat sesi ditutup. |
| **Persetujuan Izin Praktikan** | Pengguna dapat meninjau pengajuan izin/sakit maupun kendala QR mahasiswa beserta lampiran, memfilter daftar izin (*Menunggu*, *Disetujui*, *Ditolak*), serta menyetujui, menolak, atau mengubah keputusan dengan penghitungan ulang kehadiran dan pencatatan riwayat keputusan. |
| **Manajemen Pertemuan, Modul, Tugas & Pengumuman** | Pengguna dapat menambah, mengubah, dan menghapus pertemuan, modul, tugas (dengan tenggat tanggal dan jam WIB), serta kuis, maupun membuat pengumuman termasuk pengajuan perubahan jadwal/peminjaman ruangan ke Laboran beserta pemantauan status persetujuan dan alasan penolakannya. |
| **Evaluasi, Penilaian, Rekap Nilai & Rekomendasi Sanggahan** | Pengguna dapat memfilter evaluasi tugas per pertemuan (1–12) dan per sesi (Semua, C1, C2), memeriksa rincian jawaban kuis per mahasiswa, menginput skor dan feedback, mengajukan rekap nilai 4 tahap (*Draft → Diajukan → Revisi → Divalidasi*) ke Dosen lengkap dengan catatan revisi, serta memberikan rekomendasi setuju/tolak atas sanggahan nilai praktikan ke Dosen. |
| **Presensi Mengajar, Jadwal Mengajar & Tukar Jadwal (`TJ-`)** | Pengguna dapat melakukan *check-in* mengajar lewat pindai QR dinamis (rotasi 60 detik) atau input kode harian dari Laboran, melihat jadwal mengajar mingguan, mengajukan/membatalkan/menyetujui tukar jadwal berkode `TJ-` dengan pembaruan jadwal otomatis kedua asisten, serta menandai tindak lanjut arahan Dosen. |
| **Pelaporan Kendala Perangkat (`LK-`)** | Pengguna dapat membuat laporan kendala perangkat lab (PC/software wajib nomor meja/PC; proyektor/AC/jaringan wajib detail unit/posisi) beserta foto bukti, dan memantau riwayat status serta catatan penanganan dari Laboran. |
| **Notifikasi, Profil, Keamanan Akun & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi aktivitas praktikum dengan badge belum dibaca, memperbarui profil dan foto profil, mengubah kata sandi, serta menggunakan asisten AI **Tanya Gyro**. |

---

### 3. 🔧 Laboran (Pengawas)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Presensi Mengajar Asisten** | Pengguna dapat membuat kode akses harian dan QR Code dinamis (berotasi setiap 60 detik) dengan masa berlaku untuk *check-in* asisten, serta memantau perubahan status kehadiran asisten secara real-time (*Belum Check-In → Hadir*) dan rekap kedisiplinannya. |
| **Live Monitoring & Denah Meja 4 Laboratorium** | Pengguna dapat memantau kondisi **Lab Jaringan 1–4** secara real-time, asisten yang bertugas (*on-duty*), rasio kehadiran mahasiswa, serta denah 30 meja per lab (6 baris susunan 3 \| 2) per sesi lengkap dengan status meja (*Tersedia*, *Terisi*, *Rusak*), nama pemakai, jumlah keterisian dinamis, dan penanda laporan kerusakan. |
| **Manajemen Tiket Kerusakan (`LK-`)** | Pengguna menerima laporan kerusakan berkode `LK-` dari Praktikan maupun Aslab, meninjau detail serta pratinjau/unduh foto bukti, memperbarui status tiket (*Baru → Ditangani → Selesai*) beserta catatan penanganan dan riwayat perubahan waktunya, serta mengirim notifikasi otomatis ke pelapor. |
| **Approval Peminjaman Ruangan & Cek Bentrok** | Pengguna meninjau pengajuan peminjaman ruangan dari Aslab dengan pengecekan bentrok jadwal otomatis sebelum menyetujui, atau menolak dengan pilihan alasan dan catatan wajib yang tampil pada kartu status Aslab. |
| **Manajemen Inventaris Perangkat & Software (4 Lab)** | Pengguna dapat mengelola inventaris pada 4 tab laboratorium (*Lab Jaringan 1–4*), menambah perangkat baru (nomor meja/kode PC, spesifikasi, kondisi), serta mengelola (CRUD) daftar software per lab (nama, versi, status instalasi, cakupan semua PC/PC tertentu) dengan persentase kelengkapan software terhitung dinamis. |
| **Notifikasi, Profil, Keamanan Akun & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi tiket kerusakan, pengajuan ruangan, dan presensi asisten dengan badge belum dibaca, memperbarui profil dan foto profil, mengubah kata sandi, serta mengakses asisten AI **Tanya Gyro**. |

---

### 4. 👨‍🏫 Dosen Pengampu

| Fitur | Deskripsi |
|---|---|
| **Dashboard Metrik & Monitoring Kelas** | Pengguna dapat memantau ringkasan statistik tingkat kehadiran mahasiswa, grafik rata-rata performa nilai seluruh kelas praktikum yang diampu, progres pertemuan, serta pemilih **Ganti Praktikum** pada halaman Validasi dan Rekap Nilai. |
| **Validasi Rekap Nilai Akhir (4 Tahap) & Rincian Per Modul** | Pengguna dapat meninjau rekapitulasi nilai akhir lengkap dengan rincian per modul (Modul 1–12: tugas, kuis, kehadiran, nilai), memvalidasi nilai akhir (*Draft → Diajukan → Revisi → Divalidasi*), atau mengirimkan permintaan revisi wajib catatan perbaikan ke Aslab. |
| **Keputusan Akhir Sanggahan Nilai** | Pengguna dapat meninjau sanggahan nilai mahasiswa beserta rekomendasi dan catatan Aslab, lalu menetapkan keputusan akhir (menyetujui untuk mengubah nilai resmi sekaligus mencatat log perubahan nilai, atau menolak dengan alasan wajib) disertai notifikasi otomatis ke Praktikan dan Aslab. |
| **Generate & Riwayat Unduhan Laporan** | Pengguna dapat memilih praktikum, periode, dan cakupan laporan (Kehadiran, Nilai Akhir, dan Rekap Kedisiplinan Asisten) untuk mengunduh berkas berformat **XLSX** atau **PDF**, dengan seluruh riwayat unduhan tercatat (laporan terbaru hari ini tampil paling atas) dan dapat diunduh ulang. |
| **Peringatan Dini & Arahan ke Asisten** | Pengguna dapat memantau daftar mahasiswa berisiko (kehadiran < 75% atau rata-rata nilai < 70) lengkap dengan pencarian nama/NIM serta filter mata kuliah dan sesi, melihat detail riwayat kehadiran, serta mengirim arahan berkategori ke Aslab dan memantau status tindak lanjutnya (*Menunggu → Sudah Ditindaklanjuti*). |
| **Notifikasi, Profil, Keamanan Akun & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi validasi nilai, sanggahan, tindak lanjut arahan, dan peringatan dini dengan badge belum dibaca, memperbarui profil dan foto profil, mengubah kata sandi, serta mengakses asisten AI **Tanya Gyro**. |

