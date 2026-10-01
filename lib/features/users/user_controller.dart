import 'package:flutter/material.dart';

class ShiftSchedule {
  final String id;
  final String day;
  final String time;
  final String lab;
  final String matkul;
  final String assistantName;
  bool isSwapRequested;

  ShiftSchedule({
    required this.id,
    required this.day,
    required this.time,
    required this.lab,
    required this.matkul,
    required this.assistantName,
    this.isSwapRequested = false,
  });
}

class UserController extends ChangeNotifier {
  static final UserController instance = UserController._internal();
  factory UserController() => instance;
  UserController._internal();

  final List<ShiftSchedule> _shifts = [
    ShiftSchedule(
      id: 'S-01',
      day: 'Senin',
      time: '13:00 - 15:30 WIB',
      lab: 'Lab Komputer 3',
      matkul: 'Pemrograman Mobile (Kelas A)',
      assistantName: 'Abbil Rizki Abdillah',
    ),
    ShiftSchedule(
      id: 'S-02',
      day: 'Rabu',
      time: '08:00 - 10:30 WIB',
      lab: 'Lab Basis Data',
      matkul: 'Basis Data Terdistribusi (Kelas B)',
      assistantName: 'Daniele Christian Siahaan',
    ),
    ShiftSchedule(
      id: 'S-03',
      day: 'Kamis',
      time: '10:00 - 12:30 WIB',
      lab: 'Lab Jaringan & IoT',
      matkul: 'Pemrograman Web Lanjut (Kelas C)',
      assistantName: 'Reagan Brian Siahaan',
    ),
    ShiftSchedule(
      id: 'S-04',
      day: 'Jumat',
      time: '13:30 - 16:00 WIB',
      lab: 'Lab Komputer 2',
      matkul: 'Pemrograman Mobile (Kelas B)',
      assistantName: 'Andre Al Farizi Sebayang',
    ),
  ];

  List<ShiftSchedule> get shifts => _shifts;

  void requestShiftSwap(String shiftId) {
    final index = _shifts.indexWhere((s) => s.id == shiftId);
    if (index != -1) {
      _shifts[index].isSwapRequested = !_shifts[index].isSwapRequested;
      notifyListeners();
    }
  }
}
