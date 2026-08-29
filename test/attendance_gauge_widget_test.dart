import 'package:attendx/widgets/attendance_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AttendanceGauge displays the formatted percentage',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AttendanceGauge(percentage: 82.456)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('82.5%'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('AttendanceGauge labels critical attendance correctly',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AttendanceGauge(percentage: 40)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Critical'), findsOneWidget);
  });
}
