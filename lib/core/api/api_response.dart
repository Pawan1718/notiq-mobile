class ApiResponse<T> {
  const ApiResponse(
      {required this.success,
      required this.message,
      required this.data,
      required this.errors,
      this.traceId});

  final bool success;
  final String message;
  final T? data;
  final List<String> errors;
  final String? traceId;

  factory ApiResponse.fromJson(
          Map<String, dynamic> json, T Function(Object?) parseData) =>
      ApiResponse<T>(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        data: json['data'] == null ? null : parseData(json['data']),
        errors: (json['errors'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        traceId: json['traceId']?.toString(),
      );
}

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
