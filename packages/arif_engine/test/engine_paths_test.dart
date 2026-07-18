import 'dart:io';

import 'package:arif_engine/arif_engine.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('EngineBinaryLocator finds named binary in search dir', () async {
    final dir = await Directory.systemTemp.createTemp('arif-engine-');
    addTearDown(() => dir.delete(recursive: true));

    final bin = File(p.join(dir.path, 'aria2-next'));
    await bin.writeAsString('#!/bin/sh\n');
    await Process.run('chmod', ['+x', bin.path]);

    final locator = EngineBinaryLocator(
      bundledSearchDirs: [dir.path],
      environment: {'PATH': ''},
      pathEnv: '',
    );

    final found = await locator.find();
    expect(found, bin.absolute.path);
  });

  test('EngineBinaryLocator respects ARIF_ENGINE_PATH', () async {
    final dir = await Directory.systemTemp.createTemp('arif-engine-env-');
    addTearDown(() => dir.delete(recursive: true));
    final bin = File(p.join(dir.path, 'custom-aria2'));
    await bin.writeAsString('x');

    final locator = EngineBinaryLocator(
      bundledSearchDirs: const [],
      environment: {'ARIF_ENGINE_PATH': bin.path, 'PATH': ''},
      pathEnv: '',
    );
    expect(await locator.find(), bin.absolute.path);
  });

  test('EngineDataPaths.ensure creates dirs and session', () async {
    final dir = await Directory.systemTemp.createTemp('arif-data-');
    addTearDown(() => dir.delete(recursive: true));
    final paths = EngineDataPaths(root: dir.path);
    await paths.ensure();
    expect(await Directory(paths.downloadDir).exists(), isTrue);
    expect(await File(paths.sessionPath).exists(), isTrue);
  });
}
