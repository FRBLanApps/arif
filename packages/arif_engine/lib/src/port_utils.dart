import 'dart:io';

/// Returns true if something is already accepting TCP on [port] at [host].
Future<bool> isPortOpen(
  int port, {
  String host = '127.0.0.1',
  Duration timeout = const Duration(milliseconds: 300),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    await socket.close();
    return true;
  } on Object {
    return false;
  }
}

/// Finds a free TCP port, preferring [preferred] when available.
Future<int> findFreePort({
  int preferred = 6800,
  int searchFrom = 6800,
  int searchTo = 6899,
  String host = '127.0.0.1',
}) async {
  if (!await isPortOpen(preferred, host: host)) {
    return preferred;
  }
  for (var port = searchFrom; port <= searchTo; port++) {
    if (port == preferred) continue;
    if (!await isPortOpen(port, host: host)) {
      return port;
    }
  }
  // OS-assigned ephemeral
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}
