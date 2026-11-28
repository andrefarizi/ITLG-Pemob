import 'package:flutter/material.dart';

import '../../../core/services/praktikum_sync_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';
import '../../praktikan/widgets/praktikan_ui.dart';
import '../aslab_nav.dart';

class AslabTambahPertemuanPage extends StatefulWidget {
  final AslabNav nav;
  final String courseId;
  final int meetingNumber;

  const AslabTambahPertemuanPage({
    super.key,
    required this.nav,
    required this.courseId,
    required this.meetingNumber,
  });

  @override
  State<AslabTambahPertemuanPage> createState() =>
      _AslabTambahPertemuanPageState();
}

class _AslabTambahPertemuanPageState extends State<AslabTambahPertemuanPage> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  final TextEditingController _topic = TextEditingController();
  late DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')} '
      '${_months[date.month - 1]} ${date.year}';

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _save() async {
    final topic = _topic.text.trim();
    if (topic.length < 3) {
      labToast(context, 'Isi topik pertemuan minimal 3 karakter');
      return;
    }
    if (_saving) return;

    setState(() => _saving = true);
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    try {
      await PraktikumSyncService.instance.createMeetingFromAslab(
        courseId: widget.courseId,
        meetingNumber: widget.meetingNumber,
        topic: topic,
        dateLabel: '${_formatDate(_date)} • ${course.jadwalAbsensi}',
      );
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        labToast(context, error.message);
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    labToast(context, 'Pertemuan ${widget.meetingNumber} berhasil ditambahkan');
  }

  @override
  Widget build(BuildContext context) {
    final course = PraktikumSyncService.instance.courseById(widget.courseId);
    return LabSubPage(
      onLogoTap: widget.nav.home,
      children: [
        LabCard(
          children: [
            LabOverline(
              overline: 'Praktikum ${course.name} • ${course.kelas}',
              title: 'Tambah Pertemuan',
            ),
            Text(
              'Pertemuan ${widget.meetingNumber} dari 12',
              style: labText(14, w: kSemiBold),
            ),
            PrakField(
              label: 'Topik Pertemuan',
              child: PrakInput(
                controller: _topic,
                leadingIcon: 'book_open',
                hint: 'Contoh: Navigasi dan Routing',
              ),
            ),
            PrakField(
              label: 'Tanggal',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _selectDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: ItlgColors.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const LabIcon(
                        'calendar',
                        size: 18,
                        color: ItlgColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatDate(_date),
                          style: labText(14, c: ItlgColors.text),
                        ),
                      ),
                      const LabIcon(
                        'chevron_down',
                        size: 16,
                        color: ItlgColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Jadwal kelas: ${course.jadwalAbsensi}',
              style: labText(12, c: ItlgColors.textSubtle),
            ),
          ],
        ),
        LabPrimaryButton(
          icon: _saving ? 'clock' : 'check',
          label: _saving ? 'Menyimpan...' : 'Simpan Pertemuan',
          large: true,
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}
