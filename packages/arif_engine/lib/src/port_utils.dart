import 'dart:io';

/// 探测 [host]:[port] 是否已有进程在监听（TCP connect 成功即视为占用）。
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

/// 找空闲 TCP 端口：优先 [preferred]，否则在 [searchFrom]–[searchTo] 扫描。
///
/// 区间内都忙则让 OS 分配临时端口（bind 0）。
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
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}
