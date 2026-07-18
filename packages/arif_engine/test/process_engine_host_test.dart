import 'dart:io';

import 'package:arif_core/arif_core.dart';
import 'package:arif_engine/arif_engine.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('ProcessEngineHost fails when binary missing', () async {
    final host = ProcessEngineHost(
      executablePath: '/no/such/aria2-binary-${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(host.dispose);

    await expectLater(
      host.start(
        EngineConfig(
          downloadDir: Directory.systemTemp.path,
          sessionPath: p.join(Directory.systemTemp.path, 'x.session'),
          rpcPort: 16800,
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(host.currentStatus.lifecycle, EngineLifecycle.crashed);
  });

  test('ProcessEngineHost starts real aria2 when available', () async {
    final binary = await const EngineBinaryLocator().find();
    if (binary == null) {
      // CI / machines without aria2 — skip integration portion.
      return;
    }

    final root = await Directory.systemTemp.createTemp('arif-proc-');
    addTearDown(() => root.delete(recursive: true));

    final paths = EngineDataPaths(root: root.path);
    await paths.ensure();

    final freePort = await findFreePort(preferred: 16810, searchFrom: 16810, searchTo: 16900);
    final host = ProcessEngineHost(
      executablePath: binary,
      readyTimeout: const Duration(seconds: 20),
    );
    addTearDown(() async {
      await host.stop();
      await host.dispose();
    });

    await host.start(
      EngineConfig(
        downloadDir: paths.downloadDir,
        sessionPath: paths.sessionPath,
        rpcPort: freePort,
      ),
    );

    expect(host.isRunning, isTrue);
    expect(host.localRpc, isNotNull);
    expect(host.localRpc!.port, freePort);

    await host.stop();
    expect(host.currentStatus.lifecycle, EngineLifecycle.stopped);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
