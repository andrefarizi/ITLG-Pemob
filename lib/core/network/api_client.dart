class ApiResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;

  const ApiResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });
}

class ApiClient {
  static const String baseUrl = 'https://api.itlg.lab.ac.id/v1';

  // Simulasi client HTTP
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ApiResponse(
      isSuccess: true,
      message: 'OK',
      data: {'status': 'connected'},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse(
      isSuccess: true,
      message: 'Berhasil memproses data',
      data: body,
    );
  }
}
