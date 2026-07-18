import 'dart:io';

import 'package:arif_engine/arif_engine.dart';
import 'package:test/test.dart';

void main() {
  test('isPortOpen false for unused port', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final free = server.port;
    await server.close();
    // After close, may still race; pick high ephemeral-like via bind 0 again conceptually
    expect(await isPortOpen(free), isFalse);
  });

  test('findFreePort returns preferred when free', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final preferred = server.port;
    await server.close();
    // preferred just closed — should be free
    final port = await findFreePort(
      preferred: preferred,
      searchFrom: preferred,
      searchTo: preferred + 10,
    );
    expect(port, preferred);
  });

  test('findFreePort skips occupied preferred', () async {
    final occupied = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(occupied.close);
    final free = await findFreePort(
      preferred: occupied.port,
      searchFrom: occupied.port,
      searchTo: occupied.port + 50,
    );
    expect(free, isNot(occupied.port));
    expect(await isPortOpen(free), isFalse);
  });
}
