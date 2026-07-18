/// JSON-RPC 业务错误或 HTTP 传输错误。
class Aria2Exception implements Exception {
  Aria2Exception({
    this.code,
    required this.message,
    this.data,
  });

  final int? code;
  final String message;
  final Object? data;

  @override
  String toString() =>
      'Aria2Exception(${code != null ? 'code=$code, ' : ''}message=$message)';
}
