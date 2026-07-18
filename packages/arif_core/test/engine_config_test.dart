import 'package:arif_core/arif_core.dart';
import 'package:test/test.dart';

void main() {
  test('toProcessArgs enables RPC and session flags', () {
    final config = EngineConfig(
      downloadDir: '/tmp/dl',
      sessionPath: '/tmp/aria2.session',
      rpcPort: 6800,
      rpcSecret: 'secret',
    );

    final args = config.toProcessArgs(sessionFileExists: true);
    expect(args, contains('--enable-rpc=true'));
    expect(args, contains('--rpc-listen-port=6800'));
    expect(args, contains('--rpc-secret=secret'));
    expect(args, contains('--rpc-listen-all=false'));
    expect(args, contains('--dir=/tmp/dl'));
    expect(args, contains('--input-file=/tmp/aria2.session'));
    expect(args, contains('--save-session=/tmp/aria2.session'));
  });

  test('toProcessArgs omits input-file when session missing', () {
    final config = EngineConfig(
      downloadDir: '/tmp/dl',
      sessionPath: '/tmp/aria2.session',
      rpcPort: 6801,
    );
    final args = config.toProcessArgs(sessionFileExists: false);
    expect(args.any((a) => a.startsWith('--input-file=')), isFalse);
  });
}
