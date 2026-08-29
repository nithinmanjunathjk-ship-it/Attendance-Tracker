import 'dart:math' as math;

/// Result of a "classes needed to reach target" calculation.
class ClassesNeededResult {
  /// Number of additional classes that must be attended consecutively.
  final int classesNeeded;

  /// Whether the target is already met (0 classes needed).
  final bool alreadyMet;

  /// Whether the target is mathematically unreachable (e.g. target is
  /// 100% but at least one class has already been missed).
  final bool unreachable;

  const ClassesNeededResult({
    required this.classesNeeded,
    required this.alreadyMet,
    required this.unreachable,
  });
}

/// Result of a "maximum classes that can be missed" calculation.
class MaxMissableResult {
  /// Maximum number of additional classes that can be missed while still
  /// meeting the target.
  final int maxMissable;

  /// True if even one more absence would drop below target right now.
  final bool cannotMissAny;

  const MaxMissableResult({
    required this.maxMissable,
    required this.cannotMissAny,
  });
}

/// Pure, unit-testable attendance math.
///
/// All formulas operate on:
///   P = present count
///   A = absent count
///   N = total classes = P + A
///   target = target percentage, expressed as 0-100 (e.g. 75.0)
class AttendanceCalculator {
  AttendanceCalculator._();

  /// Attendance = Present / Total * 100
  static double currentPercentage({required int present, required int total}) {
    if (total <= 0) return 0.0;
    return (present / total) * 100.0;
  }

  /// Smallest integer x such that (P + x) / (N + x) >= target / 100.
  ///
  /// Attending x more classes (each one counts as both present and total).
  static ClassesNeededResult classesNeededForTarget({
    required int present,
    required int total,
    required double targetPercentage,
  }) {
    final t = targetPercentage.clamp(0.0, 100.0) / 100.0;

    if (total < 0 || present < 0 || present > total) {
      return const ClassesNeededResult(
        classesNeeded: 0,
        alreadyMet: false,
        unreachable: true,
      );
    }

    // Already at or above target.
    final current = total == 0 ? 0.0 : present / total;
    if (current >= t) {
      return const ClassesNeededResult(
        classesNeeded: 0,
        alreadyMet: true,
        unreachable: false,
      );
    }

    // Target of 100% can only ever be met if there are zero absences
    // already recorded — attending more classes cannot erase a past miss.
    if (t >= 1.0) {
      final absent = total - present;
      if (absent > 0) {
        return const ClassesNeededResult(
          classesNeeded: 0,
          alreadyMet: false,
          unreachable: true,
        );
      }
      return const ClassesNeededResult(
        classesNeeded: 0,
        alreadyMet: true,
        unreachable: false,
      );
    }

    // x >= (t*N - P) / (1 - t)
    final numerator = (t * total) - present;
    final denominator = 1 - t;
    final rawX = numerator / denominator;

    var x = rawX.ceil();
    if (x < 0) x = 0;

    // Guard against floating point edge cases by nudging up until it
    // actually satisfies the inequality.
    while ((present + x) / (total + x) < t) {
      x++;
    }

    return ClassesNeededResult(
      classesNeeded: x,
      alreadyMet: false,
      unreachable: false,
    );
  }

  /// Maximum integer x such that P / (N + x) >= target / 100.
  ///
  /// Missing x more classes (each one counts toward total only).
  static MaxMissableResult maxClassesMissable({
    required int present,
    required int total,
    required double targetPercentage,
  }) {
    final t = targetPercentage.clamp(0.0, 100.0) / 100.0;

    if (total < 0 || present < 0 || present > total || t <= 0) {
      return const MaxMissableResult(maxMissable: 0, cannotMissAny: true);
    }

    if (t == 0) {
      return const MaxMissableResult(maxMissable: 1 << 30, cannotMissAny: false);
    }

    // x <= P / t - N
    final rawX = (present / t) - total;
    var x = rawX.floor();
    if (x < 0) x = 0;

    // Guard: ensure it still satisfies the inequality (floating point safety).
    while (x > 0 && present / (total + x) < t) {
      x--;
    }

    final current = total == 0 ? 0.0 : present / total;
    final cannotMissAny = x <= 0 && current < t + 1e-9
        ? true
        : (x == 0);

    return MaxMissableResult(
      maxMissable: x,
      cannotMissAny: cannotMissAny,
    );
  }

  /// Projected percentage if the next [k] classes are all attended.
  static double projectedAfterAttending({
    required int present,
    required int total,
    required int k,
  }) {
    final kk = math.max(0, k);
    final newTotal = total + kk;
    if (newTotal <= 0) return 0.0;
    return ((present + kk) / newTotal) * 100.0;
  }

  /// Projected percentage if the next [k] classes are all missed.
  static double projectedAfterMissing({
    required int present,
    required int total,
    required int k,
  }) {
    final kk = math.max(0, k);
    final newTotal = total + kk;
    if (newTotal <= 0) return 0.0;
    return (present / newTotal) * 100.0;
  }
}
