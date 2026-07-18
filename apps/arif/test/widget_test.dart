import 'package:flutter_test/flutter_test.dart';
import 'package:arif/src/app.dart';

void main() {
  testWidgets('Home shows tasks chrome', (tester) async {
    await tester.pumpWidget(const ArifApp());
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}
