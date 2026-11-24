import 'package:flutter/material.dart';

import '../../../core/services/lab_desk_sync_service.dart';
import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/services/presensi_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../auth/auth_controller.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../praktikan_nav.dart';
import '../praktikan_store.dart';
import '../widgets/praktikan_ui.dart';

/// Halaman Detail Pertemuan Praktikan.
class PraktikanDetailPertemuanPage extends StatelessWidget {
  final PraktikanNav nav;
  final PrakCourse course;
  final PrakMeeting meeting;

  const PraktikanDetailPertemuanPage({
    super.key,
    required this.nav,
    required this.course,
    required this.meeting,
  });

  bool get _isCurrent => meeting.number >= 4;

  String get _title => meeting.module.replaceFirst(' • ', ' : ');

  String get _meta {
    final date = meeting.date.split(' • ').first;
    final jam = course.jam.replaceAll(' WIB', '');
    return 'Pertemuan ${meeting.number} • $date • $jam';
  }

  String get _desc {
    if (meeting.description.isNotEmpty) return meeting.description;
    if (meeting.number == 4) return course.modulDesc;
    return 'Materi, tugas, dan kuis untuk ${_title.toLowerCase()}.';
  }

  @override
  Widget build(BuildContext context) {
    final sync = PraktikumSyncService.instance;
    final presensi = PresensiSyncService.instance;
    final desks = LabDeskSyncService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, presensi, desks]),
      builder: (context, _) {
        final userId = AuthController.instance.userIdentifier;
        final sub = sync.submissionFor(course.id, meeting.number, userId);
        final attempt = sync.quizAttemptFor(course.id, meeting.number, userId);

        final taskSubmitted = !_isCurrent || (sub != null && sub.isSubmitted);
        final quizDone = !_isCurrent || attempt != null;

        // Hanya tampilkan konten yang memang diterbitkan Aslab.
        final hasMateri = meeting.number == 4 ||
            meeting.materiTitle.isNotEmpty ||
            meeting.materiFile.isNotEmpty;
        final hasTugas = meeting.number == 4 || meeting.tugasTitle.isNotEmpty;
        final hasKuis = meeting.number == 4 || meeting.kuisTitle.isNotEmpty;
        final soalCount = sync.questionsForCourse(course.id).length;
        final materiFileLabel = meeting.materiFile.isNotEmpty
            ? meeting.materiFile
            : (meeting.number == 4 ? course.materiFile : 'Berkas materi');
        final materiLabel = meeting.materiTitle.isNotEmpty
            ? meeting.materiTitle
            : (meeting.number == 4
                ? course.materiTitle
                : 'Materi ${_title.split(' : ').last}');

        final tugasLabel = meeting.tugasTitle.isNotEmpty
            ? meeting.tugasTitle
            : (meeting.number == 4
                ? course.tugasTitle
                : 'Tugas ${meeting.number} : ${_title.split(' : ').last}');

        final tugasSub = _isCurrent
            ? (meeting.tugasDeadline.isNotEmpty
                ? meeting.tugasDeadline
                : course.tugasDeadline)
            : 'Sudah dinilai asisten';

        final kuisLabel = meeting.kuisTitle.isNotEmpty
            ? meeting.kuisTitle
            : (_isCurrent
                ? course.preTest
                : 'Pre-Test Modul ${meeting.number}');

        final kuisSub = attempt != null
            ? '$soalCount soal • Nilai ${attempt.score} / 100'
            : '$soalCount soal • 10 menit';

        return LabSubPage(
          onLogoTap: nav.home,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LabColumn(
                gap: 8,
                children: [
                  Text(_meta,
                      style: labText(12, w: kMedium, c: LabColors.textGrey)),
                  Text(_title, style: labText(22, w: kBold)),
                  Text(_desc,
                      style: labText(14, c: LabColors.textGrey)
                          .copyWith(height: 1.4)),
                ],
              ),
            ),
            _Section(
              title: 'Meja Praktikum',
              child: _MejaSection(
                course: course,
                meeting: meeting,
                onPilihMeja: () => nav.pilihMeja(context),
                onPresensi: () => nav.presensi(context),
              ),
            ),
            _Section(
              title: 'Materi',
              child: !hasMateri
                  ? const _EmptyCard('Belum ada materi untuk pertemuan ini.')
                  : _WhiteCard(
                onTap: () =>
                    nav.detailMateri(context, course: course, meeting: meeting),
                children: [
                  _ItemRow(
                    icon: 'book_open_solid',
                    iconColor: ItlgColors.secondary,
                    title: materiLabel,
                    lines: [
                      Text(materiFileLabel,
                          style: labText(12, c: LabColors.textGrey)),
                    ],
                    trailing: Text('Lihat',
                        style: labText(13,
                            w: kSemiBold, c: ItlgColors.primary)),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Tugas',
              child: !hasTugas
                  ? const _EmptyCard('Belum ada tugas untuk pertemuan ini.')
                  : _WhiteCard(
                children: [
                  _ItemRow(
                    icon: 'h_clipboard',
                    iconColor: ItlgColors.primaryDark,
                    title: tugasLabel,
                    lines: [
                      Text(tugasSub,
                          style: labText(12, c: LabColors.textGrey)),
                      taskSubmitted
                          ? const PrakSoftChip.done('Sudah Dikumpulkan')
                          : const PrakSoftChip.warn('Belum Dikumpulkan'),
                    ],
                  ),
                  taskSubmitted
                      ? _Button.outline('Lihat Pengumpulan',
                          onTap: () => nav.editTugas(context,
                              course: course, meeting: meeting))
                      : _Button.primary('Kumpulkan Tugas',
                          onTap: () => nav.editTugas(context,
                              course: course, meeting: meeting)),
                ],
              ),
            ),
            _Section(
              title: 'Kuis',
              child: !hasKuis
                  ? const _EmptyCard('Belum ada kuis untuk pertemuan ini.')
                  : _WhiteCard(
                children: [
                  _ItemRow(
                    icon: 'question',
                    iconColor: ItlgColors.primary,
                    title: kuisLabel,
                    lines: [
                      Text(kuisSub,
                          style: labText(12, c: LabColors.textGrey)),
                      quizDone
                          ? const PrakSoftChip.done('Sudah Dikerjakan')
                          : const PrakSoftChip.warn('Belum Dikerjakan'),
                    ],
                  ),
                  quizDone
                      ? _Button.outline('Lihat Hasil Kuis',
                          onTap: () => nav.hasilKuis(context,
                              course: course, meeting: meeting))
                      : _Button.primary('Kerjakan Kuis',
                          onTap: () => nav.kuis(context,
                              course: course, meeting: meeting)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Judul bagian + isinya.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return LabColumn(
      gap: 12,
      children: [
        Text(title, style: labText(16, w: kBold)),
        child,
      ],
    );
  }
}

/// Pilih meja langsung dari halaman pertemuan. Meja hanya bisa dipilih saat
/// sesi pertemuan ini berlangsung dan praktikan sudah presensi.
class _MejaSection extends StatelessWidget {
  final PrakCourse course;
  final PrakMeeting meeting;
  final VoidCallback onPilihMeja;
  final VoidCallback onPresensi;

  const _MejaSection({
    required this.course,
    required this.meeting,
    required this.onPilihMeja,
    required this.onPresensi,
  });

  @override
  Widget build(BuildContext context) {
    final presensi = PresensiSyncService.instance;
    final session = presensi.activeSession;
    final userId = AuthController.instance.userIdentifier;
    final isThisSession = session.isActive &&
        session.courseId == course.id &&
        session.meetingNumber == meeting.number;
    if (!isThisSession) {
      return const _EmptyCard(
          'Pilih meja tersedia saat sesi pertemuan ini berlangsung.');
    }
    final rec =
        presensi.recordFor(course.id, meeting.number, userId);
    final present = rec != null && rec.status == PrakAttend.hadir;
    if (!present) {
      return _WhiteCard(
        children: [
          _ItemRow(
            icon: 'desktop_device',
            iconColor: ItlgColors.primary,
            title: 'Belum presensi',
            lines: [
              Text('Isi presensi dulu untuk memilih meja.',
                  style: labText(12, c: LabColors.textGrey)),
            ],
          ),
          _Button.primary('Isi Presensi', onTap: onPresensi),
        ],
      );
    }
    final desk = LabDeskSyncService.instance
        .bookedDeskForUser(userId, labName: session.labName);
    return _WhiteCard(
      children: [
        _ItemRow(
          icon: 'desktop_device',
          iconColor: ItlgColors.primary,
          title: desk == null
              ? 'Belum memilih meja'
              : 'Meja ${desk.toString().padLeft(2, '0')}',
          lines: [
            Text(session.labName,
                style: labText(12, c: LabColors.textGrey)),
          ],
        ),
        _Button.primary(desk == null ? 'Pilih Meja' : 'Ubah Meja',
            onTap: onPilihMeja),
      ],
    );
  }
}

/// Kartu keterangan bila materi/tugas/kuis belum diterbitkan.
class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: Text(text, style: labText(12, c: LabColors.textGrey)),
    );
  }
}

/// Kartu kontainer putih untuk item pertemuan.
class _WhiteCard extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onTap;
  const _WhiteCard({required this.children, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ItlgColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ItlgShadows.outline,
      ),
      child: LabColumn(gap: 14, children: children),
    );
    if (onTap == null) return card;
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// Kotak ikon + judul + baris keterangan.
class _ItemRow extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final List<Widget> lines;
  final Widget? trailing;

  const _ItemRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          trailing == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        LabIconTile(icon, color: iconColor, bg: ItlgColors.surfaceDark),
        const SizedBox(width: 12),
        Expanded(
          child: LabColumn(
            gap: trailing == null ? 6 : 4,
            cross: CrossAxisAlignment.start,
            children: [
              Text(title, style: labText(14, w: kBold)),
              ...lines,
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Tombol: merah bercahaya atau putih bergaris.
class _Button extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _Button.primary(this.label, {required this.onTap}) : primary = true;
  const _Button.outline(this.label, {required this.onTap}) : primary = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: primary ? ItlgColors.primary : LabColors.bar,
          borderRadius: BorderRadius.circular(12),
          boxShadow: primary ? ItlgShadows.primary : ItlgShadows.outline,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labText(14,
              w: kBold, c: primary ? Colors.white : ItlgColors.primary),
        ),
      ),
    );
  }
}
