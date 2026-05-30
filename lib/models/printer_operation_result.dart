class PrinterOperationResult {
  const PrinterOperationResult({required this.success, this.error});

  final bool success;
  final String? error;

  factory PrinterOperationResult.fromMap(Map<dynamic, dynamic>? map) {
    return PrinterOperationResult(
      success: map?['success'] == true,
      error: map?['error']?.toString(),
    );
  }
}
