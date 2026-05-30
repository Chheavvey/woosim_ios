import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/print_history_item.dart';
import '../models/printer_device.dart';
import '../services/image_picker_service.dart';
import '../services/permission_service.dart';
import '../services/woosim_printer_service.dart';

class PrinterController extends ChangeNotifier {
  PrinterController({
    WoosimPrinterService? printerService,
    PermissionService? permissionService,
    ImagePickerService? imagePickerService,
  })  : _printerService = printerService ?? WoosimPrinterService(),
        _permissionService = permissionService ?? PermissionService(),
        _imagePickerService = imagePickerService ?? ImagePickerService() {
    _history.add(
      PrintHistoryItem(
        title: 'Ready',
        subtitle: 'Photo printer initialized for 80mm',
        timestamp: DateTime.now(),
      ),
    );
  }

  final WoosimPrinterService _printerService;
  final PermissionService _permissionService;
  final ImagePickerService _imagePickerService;

  bool permissionsGranted = false;
  bool loadingPrinters = false;
  bool busy = false;
  XFile? selectedImage;
  PrinterDevice? connectedPrinter;
  String? lastError;

  final List<PrinterDevice> _printers = [];
  final List<PrintHistoryItem> _history = [];

  List<PrinterDevice> get printers => List.unmodifiable(_printers);
  List<PrintHistoryItem> get history => List.unmodifiable(_history);

  Future<String?> setup() async {
    permissionsGranted = await _permissionService.requestPrinterPermissions();
    notifyListeners();

    if (!permissionsGranted) return 'Bluetooth permission is required';
    return refreshPrinters();
  }

  Future<String?> refreshPrinters() async {
    loadingPrinters = true;
    notifyListeners();

    try {
      final enabled = await _printerService.isBluetoothEnabled();
      if (!enabled) {
        _printers.clear();
        lastError = 'Bluetooth is turned off';
        return lastError;
      }

      final devices = await _printerService.getBondedPrinters();
      _printers
        ..clear()
        ..addAll(devices);
      lastError = devices.isEmpty
          ? (Platform.isIOS ? 'No iOS BLE printer found. Keep printer on and tap Refresh again.' : 'No paired printer found')
          : null;
      return lastError;
    } catch (e) {
      lastError = e.toString();
      return lastError;
    } finally {
      loadingPrinters = false;
      notifyListeners();
    }
  }

  Future<String?> pickImage() async {
    final image = await _imagePickerService.pickPhotoFromGallery();
    if (image == null) return null;

    selectedImage = image;
    _addHistory('Image selected', image.name);
    notifyListeners();
    return 'Image selected';
  }

  Future<String?> connect(PrinterDevice device) async {
    busy = true;
    notifyListeners();

    try {
      final result = await _printerService.connect(device);
      if (result.success) {
        connectedPrinter = device;
        lastError = null;
        _addHistory('Connected', '${device.name} (${device.address})');
        return 'Connected to ${device.name}';
      }

      lastError = result.error ?? 'Connection failed';
      return lastError;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> printTestPage() async {
    busy = true;
    notifyListeners();

    try {
      final result = await _printerService.printTestReceipt();
      if (result.success) {
        _addHistory('Printed test page', connectedPrinter?.name ?? 'Unknown printer');
        return 'Printed test page';
      }

      lastError = result.error ?? 'Printer not connected';
      return lastError;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> printSelectedImage() async {
    final image = selectedImage;
    if (image == null) return 'Please choose a photo first';

    busy = true;
    notifyListeners();

    try {
      final result = await _printerService.printImage(
        imagePath: image.path,
        paperWidth: 576,
      );

      if (result.success) {
        _addHistory('Photo printed', image.name);
        return 'Printed photo on 80mm paper';
      }

      lastError = result.error ?? 'Image print failed';
      return lastError;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _addHistory(String title, String subtitle) {
    _history.insert(
      0,
      PrintHistoryItem(title: title, subtitle: subtitle, timestamp: DateTime.now()),
    );
  }
}
