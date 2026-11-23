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

## 👥 User Requirements per Role

### 1. 🎓 Praktikan (Mahasiswa)

| Fitur | Deskripsi |
|---|---|
| **Akses Jadwal, Pengumuman & Modul** | Pengguna dapat melihat jadwal praktikum mingguan (termasuk sinkronisasi ke kalender perangkat), membaca pengumuman asisten, serta melihat dan mengunduh materi atau modul pada setiap pertemuan. |
| **Presensi Anti-Kecurangan (QR, GPS & Tanda Tangan)** | Pengguna dapat melakukan presensi kehadiran melalui pemindaian QR Code dinamis menggunakan kamera atau tombol hadir berbasis validasi lokasi GPS (geofencing radius lab), dilengkapi verifikasi tanda tangan digital. |
| **Riwayat Absensi & Pengajuan Izin** | Pengguna dapat memantau rekap persentase dan detail kehadiran tiap praktikum serta mengajukan izin/sakit beserta lampiran surat bukti untuk ditinjau asisten. |
| **Pemilihan Meja Lab & Laporan Kerusakan** | Pengguna dapat memilih meja/PC yang tersedia pada denah ruang praktikum secara real-time, melihat detail meja aktif, serta melaporkan kerusakan perangkat lab langsung ke Laboran. |
| **Submission Tugas & Kuis** | Pengguna dapat mengumpulkan atau memperbarui tugas praktikum (berkas maupun tautan repositori), mengerjakan kuis praktikum, serta melihat hasil penilaiannya. |
| **Transparansi Nilai, Sanggah Nilai & Penilaian Asisten** | Pengguna dapat memantau akumulasi dan rincian nilai beserta feedback asisten, mengajukan sanggahan nilai dengan alasan dan bukti lampiran, serta memberikan penilaian kinerja asisten. |
| **Notifikasi, Profil & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi pembaruan praktikum, memperbarui data profil akun, serta menggunakan asisten AI interaktif **Tanya Gyro** untuk bantuan seputar praktikum. |

---

### 2. 🖥️ Asisten Laboratorium (Aslab)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Sesi & Presensi Praktikan** | Pengguna dapat membuka sesi presensi kelas menggunakan QR Code dinamis (auto-refresh) maupun validasi lokasi GPS, memantau kehadiran praktikan secara langsung, melihat bukti presensi/tanda tangan, serta mengubah status kehadiran secara manual. |
| **Persetujuan Izin Praktikan** | Pengguna dapat meninjau pengajuan izin/sakit mahasiswa beserta lampiran surat bukti, lalu menyetujui atau menolak pengajuan tersebut. |
| **Manajemen Pertemuan, Modul, Tugas & Pengumuman** | Pengguna dapat menambah pertemuan dan materi baru, mengelola modul serta tenggat tugas, dan membuat pengumuman (termasuk pengajuan perubahan jadwal/ruangan ke Laboran). |
| **Evaluasi, Grading Tugas & Hasil Kuis** | Pengguna dapat memeriksa pengumpulan tugas dan hasil kuis praktikan, menginput skor penilaian, serta memberikan catatan feedback yang tersinkronisasi ke praktikan dan dosen. |
| **Koordinasi Shift Jaga & Tukar Shift** | Pengguna dapat melihat jadwal shift jaga mingguan beserta QR/kode akses presensi asisten untuk Laboran, mengajukan permintaan tukar shift (*swap request*) ke asisten lain, dan memantau riwayat status pengajuannya. |
| **Pelaporan Kendala Perangkat (Issue Ticketing)** | Pengguna dapat membuat laporan kendala perangkat lab (PC, proyektor, AC, jaringan, dan lainnya) beserta detail kerusakan dan foto lampiran langsung ke Laboran. |
| **Notifikasi, Profil & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi aktivitas praktikum, memperbarui data profil akun, serta menggunakan asisten AI interaktif **Tanya Gyro**. |

---

### 3. 🔧 Laboran (Pengawas)

| Fitur | Deskripsi |
|---|---|
| **Manajemen Presensi Asisten** | Pengguna memiliki wewenang untuk men-generate kode akses presensi harian bagi Aslab yang bertugas, memverifikasi kehadiran asisten menggunakan kode akses, serta memantau status dan rekap kedisiplinan asisten. |
| **Live Monitoring & Denah Meja Lab** | Pengguna dapat memantau status ruang lab yang sedang digunakan secara real-time, asisten yang bertugas (*on-duty*), rasio kehadiran mahasiswa, serta status keterisian dan kondisi setiap meja/PC pada denah ruangan. |
| **Manajemen Tiket Perbaikan (Ticketing System)** | Pengguna menerima laporan kerusakan perangkat dari Aslab maupun Praktikan, meninjau detail serta foto bukti kerusakan, menambahkan catatan penanganan, dan memperbarui status tiket (*Baru*, *Sedang Ditangani*, *Selesai*). |
| **Approval Peminjaman Ruangan** | Pengguna memegang otoritas penuh untuk meninjau, menyetujui, atau menolak pengajuan peminjaman ruangan untuk jadwal kelas maupun praktikum pengganti. |
| **Manajemen Data Inventaris** | Pengguna dapat mengelola daftar perangkat inventaris di masing-masing laboratorium (PC, proyektor, AC, perangkat jaringan), menambahkan perangkat baru, serta memantau status kesiapannya. |
| **Notifikasi, Profil & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi tiket perbaikan, pengajuan ruangan, dan presensi asisten, mengelola profil akun, serta mengakses asisten AI interaktif **Tanya Gyro**. |

---

### 4. 👨‍🏫 Dosen Pengampu

| Fitur | Deskripsi |
|---|---|
| **Dashboard Metrik & Monitoring Kelas** | Pengguna dapat memantau ringkasan statistik tingkat kehadiran mahasiswa, grafik rata-rata performa nilai seluruh kelas praktikum yang diampu, serta progres pertemuan dan asisten pengampu. |
| **Validasi Rekapitulasi Nilai Akhir & Permintaan Revisi** | Pengguna dapat meninjau rekapitulasi nilai akhir seluruh praktikan dari asisten, memvalidasi nilai sebelum sinkronisasi akademik, atau mengirimkan permintaan revisi beserta catatan perbaikan ke asisten. |
| **Generate & Riwayat Unduhan Laporan** | Pengguna dapat memilih praktikum, periode, cakupan laporan (Kehadiran, Pelaporan Nilai Akhir, dan Rekap Kedisiplinan Asisten), serta mengunduh berkas laporan dalam format **XLSX** atau **PDF** dalam satu klik lengkap dengan riwayat unduhan. |
| **Peringatan Dini & Komunikasi Mahasiswa** | Pengguna dapat memantau daftar mahasiswa berisiko (kehadiran atau nilai di bawah batas), melihat detail riwayat kehadirannya, serta mengirim pesan peringatan/tindak lanjut kepada mahasiswa atau asisten. |
| **Notifikasi, Profil & Asisten AI (Tanya Gyro)** | Pengguna dapat menerima notifikasi validasi nilai, laporan, dan peringatan dini mahasiswa, mengelola profil akun, serta mengakses asisten AI interaktif **Tanya Gyro**. |

