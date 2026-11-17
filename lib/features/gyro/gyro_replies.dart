/// Jawaban dummy Gyro (belum terhubung backend / AI sungguhan).
///
/// Nanti cukup ganti [GyroReplies.answer] dengan pemanggilan API; halaman
/// Gyro hanya butuh `thinking` (teks gelembung saat berpikir) dan `answer`.
class GyroReply {
  /// Teks di gelembung pikiran saat Gyro "berpikir".
  final String thinking;

  /// Jawaban yang ditampilkan di chat.
  final String answer;

  /// User berterima kasih → Gyro melompat senang setelah menjawab.
  final bool isThanks;

  const GyroReply({
    required this.thinking,
    required this.answer,
    this.isThanks = false,
  });
}

class GyroReplies {
  GyroReplies._();

  static const String greeting = 'Halo! Aku Gyro, siap bantu kamu belajar.';
  static const String hint =
      'Ketik pesan dan lihat reaksiku: aku mendengarkan, berpikir, lalu '
      'menjawab.\nKamu juga bisa menyentuh aku.';

  /// Chip saran sebelum percakapan dimulai (sesuai desain Figma).
  static const List<String> introSuggestions = [
    'Jadwal hari ini',
    'Deadline tugas',
    'Tips belajar',
    'Makasih!',
  ];

  /// Chip saran saat percakapan berjalan.
  static const List<String> chatSuggestions = [
    'Nilai saya',
    'Materi Modul 4',
    'Jadwal minggu ini',
    'Tips belajar',
    'Makasih!',
  ];

  static GyroReply answer(String question) {
    final q = question.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);

    if (has(['makasih', 'terima kasih', 'thanks', 'thank you', 'tengkyu'])) {
      return const GyroReply(
        thinking: 'Hehe...',
        answer: 'Sama-sama! Semangat praktikumnya ya, aku selalu di sini '
            'kalau kamu butuh bantuan.',
        isThanks: true,
      );
    }
    if (has(['deadline', 'tenggat', 'dikumpul', 'tugas'])) {
      return const GyroReply(
        thinking: 'Hmm, aku cek daftar tugasmu dulu ya...',
        answer: 'Tugas 4 : Pembuatan Prototype Figma dikumpulkan paling '
            'lambat Senin, 29 September 2026 pukul 10:30 WIB.',
      );
    }
    if (has(['minggu ini', 'seminggu'])) {
      return const GyroReply(
        thinking: 'Hmm, aku rangkum jadwal minggu ini ya...',
        answer: 'Jadwal praktikummu minggu ini:\n'
            '• Senin, 13.00 – Pemrograman Mobile (Lab Komputer 2)\n'
            '• Rabu, 08.00 – Desain Interaksi (Lab Multimedia)\n'
            '• Jumat, 10.00 – Basis Data (Lab Komputer 1)',
      );
    }
    if (has(['besok'])) {
      return const GyroReply(
        thinking: 'Hmm, aku cek jadwalmu dulu ya...',
        answer: 'Besok kamu ada Praktikum Desain Interaksi pukul '
            '08.00 – 10.30 WIB di Lab Multimedia. Jangan telat ya!',
      );
    }
    if (has(['jadwal', 'praktikum hari', 'hari ini'])) {
      return const GyroReply(
        thinking: 'Hmm, aku cek jadwalmu dulu ya...',
        answer: 'Hari ini kamu ada Praktikum Pemrograman Mobile – Modul 4, '
            'pukul 13.00 – 15.30 WIB di Lab Komputer 2. Jangan lupa bawa '
            'laptop ya!',
      );
    }
    if (has(['nilai', 'skor'])) {
      return const GyroReply(
        thinking: 'Sebentar, aku lihat nilaimu...',
        answer: 'Rata-rata nilai praktikummu saat ini 88. Nilai tertinggi '
            'ada di Modul 2 (95). Detail lengkapnya bisa dilihat di menu '
            'Nilai.',
      );
    }
    if (has(['materi', 'modul'])) {
      return const GyroReply(
        thinking: 'Aku cari materinya dulu ya...',
        answer: 'Modul 4 membahas State Management di Flutter: setState, '
            'Provider, dan contoh kasusnya. File materinya bisa diunduh di '
            'menu Praktikum > Detail Praktikum.',
      );
    }
    if (has(['tips', 'belajar', 'saran'])) {
      return const GyroReply(
        thinking: 'Hmm, tips apa yang paling pas ya...',
        answer: 'Coba ini ya:\n'
            '1. Baca modul sebelum praktikum dimulai.\n'
            '2. Catat error yang sering muncul beserta solusinya.\n'
            '3. Kerjakan tugas sedikit demi sedikit, jangan mepet deadline.',
      );
    }
    if (has(['halo', 'pagi', 'siang', 'sore', 'malam']) ||
        RegExp(r'\bhai\b').hasMatch(q)) {
      return const GyroReply(
        thinking: 'Eh, ada yang menyapa...',
        answer: 'Halo juga! Mau tanya jadwal, deadline tugas, nilai, atau '
            'materi praktikum?',
      );
    }
    return const GyroReply(
      thinking: 'Hmm, aku pikir-pikir dulu ya...',
      answer: 'Maaf, aku belum bisa menjawab itu. Saat ini aku baru bisa '
          'bantu soal jadwal, deadline tugas, nilai, materi, dan tips '
          'belajar.',
    );
  }
}
