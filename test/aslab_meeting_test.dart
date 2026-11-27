import 'package:flutter_test/flutter_test.dart';
import 'package:itlg_mobile/core/services/praktikum_sync_service.dart';

void main() {
  test('Aslab can create and see a meeting without content', () async {
    final sync = PraktikumSyncService.instance;
    const courseId = 'pemob';
    final course = sync.courseById(courseId);
    final nextNumber =
        course.meetings.fold<int>(
          0,
          (latest, meeting) =>
              meeting.number > latest ? meeting.number : latest,
        ) +
        1;

    await sync.createMeetingFromAslab(
      courseId: courseId,
      meetingNumber: nextNumber,
      topic: 'Navigasi dan Routing',
      dateLabel: 'Sen, 02 Nov 2026 • Sen, 08:00–09:40',
    );

    expect(
      sync.meetingFor(courseId, nextNumber)?.module,
      'Modul $nextNumber • Navigasi dan Routing',
    );
    expect(
      sync.aslabCourses
          .firstWhere((item) => item.id == courseId)
          .meetings
          .any((meeting) => meeting.number == nextNumber),
      isTrue,
    );
  });
}
