import 'package:flutter_test/flutter_test.dart';
import 'package:arif/src/app.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';

void main() {
  testWidgets('Home shows disconnected chrome without auto-connect',
      (tester) async {
    final session = SessionController(
      profile: ConnectionProfile.localDefault(),
      autoStartLocalEngine: false,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ArifApp(session: session, autoConnect: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Not connected'), findsWidgets);
  });
}
