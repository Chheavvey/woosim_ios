import 'package:flutter/services.dart';

import '../models/printer_device.dart';
import '../models/printer_operation_result.dart';

class WoosimPrinterService {
  static const MethodChannel _channel = MethodChannel('woosim_printer');

  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
  }

  Future<bool> isConnected() async {
    return await _channel.invokeMethod<bool>('isConnected') ?? false;
  }

  Future<List<PrinterDevice>> getBondedPrinters() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('getBondedPrinters');
    return (raw ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(PrinterDevice.fromMap)
        .toList();
  }

  Future<PrinterOperationResult> connect(PrinterDevice device) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'connect',
      device.toMap(),
    );
    return PrinterOperationResult.fromMap(raw);
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod<void>('disconnect');
  }

  Future<PrinterOperationResult> printTestReceipt() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('printTestReceipt');
    return PrinterOperationResult.fromMap(raw);
  }

  Future<PrinterOperationResult> printImage({
    required String imagePath,
    int paperWidth = 576,
  }) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'printImage',
      {'imagePath': imagePath, 'paperWidth': paperWidth},
    );
    return PrinterOperationResult.fromMap(raw);
  }
}
