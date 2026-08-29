import 'package:attendx/core/utils/attendance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currentPercentage', () {
    test('computes basic percentage', () {
      expect(
        AttendanceCalculator.currentPercentage(present: 75, total: 100),
        75.0,
      );
    });

    test('returns 0 when total is 0', () {
      expect(
        AttendanceCalculator.currentPercentage(present: 0, total: 0),
        0.0,
      );
    });

    test('handles 100% attendance', () {
      expect(
        AttendanceCalculator.currentPercentage(present: 20, total: 20),
        100.0,
      );
    });
  });

  group('classesNeededForTarget', () {
    test('already met target requires 0 classes', () {
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 80,
        total: 100,
        targetPercentage: 75,
      );
      expect(result.alreadyMet, true);
      expect(result.classesNeeded, 0);
    });

    test('classic example: 60/100 needing 75% needs 60 more classes', () {
      // (60 + x) / (100 + x) >= 0.75  =>  x >= 60
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 60,
        total: 100,
        targetPercentage: 75,
      );
      expect(result.alreadyMet, false);
      expect(result.classesNeeded, 60);

      // Verify: attending those classes actually reaches target.
      final newPct = AttendanceCalculator.projectedAfterAttending(
        present: 60,
        total: 100,
        k: result.classesNeeded,
      );
      expect(newPct, greaterThanOrEqualTo(75.0));

      // One fewer class should NOT be enough.
      final shortPct = AttendanceCalculator.projectedAfterAttending(
        present: 60,
        total: 100,
        k: result.classesNeeded - 1,
      );
      expect(shortPct, lessThan(75.0));
    });

    test('never returns negative classes needed', () {
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 10,
        total: 10,
        targetPercentage: 50,
      );
      expect(result.classesNeeded, greaterThanOrEqualTo(0));
    });

    test('100% target is unreachable once a class has been missed', () {
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 9,
        total: 10,
        targetPercentage: 100,
      );
      expect(result.unreachable, true);
    });

    test('100% target already met with zero absences', () {
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 10,
        total: 10,
        targetPercentage: 100,
      );
      expect(result.alreadyMet, true);
      expect(result.unreachable, false);
    });

    test('handles zero total classes gracefully', () {
      final result = AttendanceCalculator.classesNeededForTarget(
        present: 0,
        total: 0,
        targetPercentage: 75,
      );
      expect(result.classesNeeded, greaterThanOrEqualTo(0));
    });
  });

  group('maxClassesMissable', () {
    test('classic example: 90/100 with 75% target can miss 20', () {
      // 90 / (100 + x) >= 0.75  =>  x <= 20
      final result = AttendanceCalculator.maxClassesMissable(
        present: 90,
        total: 100,
        targetPercentage: 75,
      );
      expect(result.maxMissable, 20);

      final afterMax = AttendanceCalculator.projectedAfterMissing(
        present: 90,
        total: 100,
        k: 20,
      );
      expect(afterMax, greaterThanOrEqualTo(75.0));

      final afterOneMore = AttendanceCalculator.projectedAfterMissing(
        present: 90,
        total: 100,
        k: 21,
      );
      expect(afterOneMore, lessThan(75.0));
    });

    test('cannot miss any when already below target', () {
      final result = AttendanceCalculator.maxClassesMissable(
        present: 50,
        total: 100,
        targetPercentage: 75,
      );
      expect(result.cannotMissAny, true);
      expect(result.maxMissable, 0);
    });

    test('never returns a negative value', () {
      final result = AttendanceCalculator.maxClassesMissable(
        present: 0,
        total: 0,
        targetPercentage: 75,
      );
      expect(result.maxMissable, greaterThanOrEqualTo(0));
    });
  });

  group('projections', () {
    test('projectedAfterAttending increases percentage', () {
      final before = AttendanceCalculator.currentPercentage(present: 50, total: 100);
      final after = AttendanceCalculator.projectedAfterAttending(
        present: 50,
        total: 100,
        k: 10,
      );
      expect(after, greaterThan(before));
    });

    test('projectedAfterMissing decreases percentage', () {
      final before = AttendanceCalculator.currentPercentage(present: 50, total: 100);
      final after = AttendanceCalculator.projectedAfterMissing(
        present: 50,
        total: 100,
        k: 10,
      );
      expect(after, lessThan(before));
    });

    test('negative k is treated as zero', () {
      final result = AttendanceCalculator.projectedAfterAttending(
        present: 50,
        total: 100,
        k: -5,
      );
      expect(result, 50.0);
    });
  });
}
