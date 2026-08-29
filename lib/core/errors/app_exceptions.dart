/// Base class for all application-level exceptions.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

class DuplicateAttendanceException extends AppException {
  const DuplicateAttendanceException()
      : super('Attendance for this subject, date and class has already '
            'been recorded.');
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}
