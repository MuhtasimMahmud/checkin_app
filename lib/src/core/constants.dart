class FirestorePaths {
  static const stateDoc = 'checkin_state/active';
  static const pointsCol = 'checkin_points';
  static String attendances(String pointId) =>
      'checkin_points/$pointId/attendances';
}

class AttendanceStatus {
  static const inStatus = 'in';
  static const outStatus = 'out';
}
