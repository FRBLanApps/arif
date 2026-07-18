/// Error returned by aria2 JSON-RPC or the transport layer.
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
