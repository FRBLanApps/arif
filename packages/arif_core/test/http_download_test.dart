import 'package:arif_core/arif_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseUriList', () {
    test('splits lines and dedupes', () {
      expect(
        parseUriList('https://a.com/1\nhttps://b.com/2\nhttps://a.com/1'),
        ['https://a.com/1', 'https://b.com/2'],
      );
    });

    test('trims blanks', () {
      expect(parseUriList('  \n  https://x.com  \n'), ['https://x.com']);
    });
  });

  group('HttpDownloadOptions', () {
    test('toAria2Options maps keys', () {
      final opts = HttpDownloadOptions(
        dir: '/tmp/dl',
        out: 'file.zip',
        split: 8,
        maxConnectionPerServer: 4,
        referer: 'https://ref.example/',
        userAgent: 'arif/0.1',
        headers: ['Cookie: a=1', 'X-Test: 2'],
      ).toAria2Options();

      expect(opts['dir'], '/tmp/dl');
      expect(opts['out'], 'file.zip');
      expect(opts['split'], '8');
      expect(opts['max-connection-per-server'], '4');
      expect(opts['referer'], 'https://ref.example/');
      expect(opts['user-agent'], 'arif/0.1');
      expect(opts['header'], 'Cookie: a=1\nX-Test: 2');
      expect(opts['continue'], 'true');
    });
  });

  group('TaskFilter', () {
    test('buckets match AriaNg semantics', () {
      expect(TaskFilter.active.matchesStatus(TaskStatus.active), isTrue);
      expect(TaskFilter.active.matchesStatus(TaskStatus.paused), isFalse);
      expect(TaskFilter.waiting.matchesStatus(TaskStatus.paused), isTrue);
      expect(TaskFilter.waiting.matchesStatus(TaskStatus.waiting), isTrue);
      expect(TaskFilter.stopped.matchesStatus(TaskStatus.complete), isTrue);
      expect(TaskFilter.stopped.matchesStatus(TaskStatus.error), isTrue);
      expect(TaskFilter.all.matchesStatus(TaskStatus.unknown), isTrue);
    });
  });

  test('guessFilenameFromUri', () {
    expect(
      guessFilenameFromUri('https://example.com/path/file%20name.zip?x=1'),
      'file name.zip',
    );
  });

  test('isSupportedHttpUri', () {
    expect(isSupportedHttpUri('https://a.com'), isTrue);
    expect(isSupportedHttpUri('magnet:?xt=urn:btih:x'), isFalse);
  });
}
