import '../models/eye_health_record.dart';

class EyeHealthService {
  static EyeHealthRecord getTodayRecord() {
    return const EyeHealthRecord(screenTimeMinutes: 275, breaksTaken: 6);
  }
}
