import 'dart:convert';

import 'package:arif_rpc/arif_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getVersion and tellActive parse RPC payloads', () async {
    final mock = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final method = body['method'] as String;
      final id = body['id'];

      Object? result;
      if (method == 'aria2.getVersion') {
        result = {
          'version': '1.37.0',
          'enabledFeatures': ['BitTorrent', 'WebSocket'],
        };
      } else if (method == 'aria2.tellActive') {
        result = [
          {
            'gid': 'gid1',
            'status': 'active',
            'totalLength': '100',
            'completedLength': '50',
            'uploadLength': '0',
            'downloadSpeed': '10',
            'uploadSpeed': '0',
            'connections': '1',
            'files': [
              {
                'index': '1',
                'path': '/tmp/a.bin',
                'length': '100',
                'completedLength': '50',
                'selected': 'true',
                'uris': [
                  {'uri': 'https://example.com/a.bin'},
                ],
              },
            ],
          },
        ];
      } else {
        return http.Response('{"error":"unknown"}', 500);
      }

      return http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = Aria2Client(
      config: const RpcConnectionConfig(host: '127.0.0.1', secret: 's3cret'),
      httpClient: mock,
    );

    final version = await client.getVersion();
    expect(version.version, '1.37.0');

    final active = await client.tellActive();
    expect(active, hasLength(1));
    expect(active.single.displayName, 'a.bin');
    expect(active.single.progress, 0.5);

    client.close();
  });

  test('token is injected into params', () async {
    List<Object?>? seenParams;
    final mock = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      seenParams = (body['params'] as List).cast<Object?>();
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {
            'downloadSpeed': '0',
            'uploadSpeed': '0',
            'numActive': '0',
            'numWaiting': '0',
            'numStopped': '0',
            'numStoppedTotal': '0',
          },
        }),
        200,
      );
    });

    final client = Aria2Client(
      config: const RpcConnectionConfig(host: '127.0.0.1', secret: 'tok'),
      httpClient: mock,
    );
    await client.getGlobalStat();
    expect(seenParams!.first, 'token:tok');
    client.close();
  });
}
