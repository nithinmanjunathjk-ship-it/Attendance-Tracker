class AppConstants {
  AppConstants._();

  static const String appName = 'AttendX';
  static const String appVersion = '1.0.0';

  static const double defaultTargetPercentage = 75.0;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> weekDaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Supabase table names
  static const String tableProfiles = 'profiles';
  static const String tableSubjects = 'subjects';
  static const String tableAttendance = 'attendance_records';
  static const String tableTimetable = 'timetable';
  static const String tableSettings = 'user_settings';
}

class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'present';
  static const String absent = 'absent';
}

class AppThemeMode {
  AppThemeMode._();

  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';
}
