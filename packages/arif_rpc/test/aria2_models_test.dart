import 'package:arif_rpc/arif_rpc.dart';
import 'package:test/test.dart';

void main() {
  test('DownloadTask.fromJson maps core fields', () {
    final task = DownloadTask.fromJson({
      'gid': 'abc',
      'status': 'active',
      'totalLength': '1000',
      'completedLength': '250',
      'uploadLength': '0',
      'downloadSpeed': '100',
      'uploadSpeed': '0',
      'connections': '2',
      'files': [
        {
          'index': '1',
          'path': '/tmp/file.bin',
          'length': '1000',
          'completedLength': '250',
          'selected': 'true',
          'uris': [
            {'uri': 'https://example.com/file.bin'},
          ],
        },
      ],
    });

    expect(task.gid, 'abc');
    expect(task.progress, 0.25);
    expect(task.displayName, 'file.bin');
    expect(task.files.single.uris.single, 'https://example.com/file.bin');
  });

  test('GlobalStat.fromJson', () {
    final stat = GlobalStat.fromJson({
      'downloadSpeed': '10',
      'uploadSpeed': '2',
      'numActive': '1',
      'numWaiting': '3',
      'numStopped': '4',
      'numStoppedTotal': '5',
    });
    expect(stat.numActive, 1);
    expect(stat.downloadSpeed, 10);
  });
}
