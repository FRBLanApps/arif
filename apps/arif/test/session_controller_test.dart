import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('SessionController connects and loads tasks', () async {
    final mock = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final method = body['method'] as String;
      final id = body['id'];

      Object? result;
      switch (method) {
        case 'aria2.getVersion':
          result = {'version': '1.37.0', 'enabledFeatures': <String>[]};
        case 'aria2.getGlobalStat':
          result = {
            'downloadSpeed': '1024',
            'uploadSpeed': '0',
            'numActive': '1',
            'numWaiting': '0',
            'numStopped': '0',
            'numStoppedTotal': '0',
          };
        case 'aria2.tellActive':
          result = [
            {
              'gid': 'g1',
              'status': 'active',
              'totalLength': '200',
              'completedLength': '100',
              'uploadLength': '0',
              'downloadSpeed': '1024',
              'uploadSpeed': '0',
              'connections': '2',
              'files': [
                {
                  'index': '1',
                  'path': '/tmp/file.bin',
                  'length': '200',
                  'completedLength': '100',
                  'selected': 'true',
                  'uris': [],
                },
              ],
            },
          ];
        case 'aria2.tellWaiting':
        case 'aria2.tellStopped':
          result = <Object?>[];
        default:
          return http.Response('bad method $method', 500);
      }

      return http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
        200,
      );
    });

    final client = Aria2Client(
      config: const RpcConnectionConfig(host: '127.0.0.1'),
      httpClient: mock,
    );
    final session = SessionController(
      profile: ConnectionProfile.localDefault(),
      client: client,
      pollInterval: const Duration(hours: 1),
      autoStartLocalEngine: false,
    );

    await session.connect();
    expect(session.isConnected, isTrue);
    expect(session.engineVersion, '1.37.0');
    expect(session.activeTasks, hasLength(1));
    expect(session.activeTasks.single.displayName, 'file.bin');
    expect(session.globalStat?.downloadSpeed, 1024);

    await session.disconnect();
    session.dispose();
  });
}
