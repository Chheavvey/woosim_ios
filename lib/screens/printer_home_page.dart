import 'package:flutter/material.dart';

import '../controllers/printer_controller.dart';
import '../models/printer_device.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'printers_tab.dart';

class PrinterHomePage extends StatefulWidget {
  const PrinterHomePage({super.key});

  @override
  State<PrinterHomePage> createState() => _PrinterHomePageState();
}

class _PrinterHomePageState extends State<PrinterHomePage> {
  final PrinterController _controller = PrinterController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAction(_controller.setup);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<String?> Function() action) async {
    final message = await action();
    if (message == null || !mounted) return;
    _showMessage(message);
  }

  Future<void> _connectPrinter(PrinterDevice device) {
    return _runAction(() => _controller.connect(device));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pages = [
          HomeTab(
            permissionsGranted: _controller.permissionsGranted,
            selectedImage: _controller.selectedImage,
            connectedPrinter: _controller.connectedPrinter,
            lastError: _controller.lastError,
            busy: _controller.busy,
            onPickImage: () => _runAction(_controller.pickImage),
            onPrintImage: () => _runAction(_controller.printSelectedImage),
            onPrintTest: () => _runAction(_controller.printTestPage),
          ),
          PrintersTab(
            permissionsGranted: _controller.permissionsGranted,
            loading: _controller.loadingPrinters || _controller.busy,
            printers: _controller.printers,
            connectedPrinter: _controller.connectedPrinter,
            onRefresh: () => _runAction(_controller.refreshPrinters),
            onConnect: _connectPrinter,
          ),
          HistoryTab(items: _controller.history),
        ];

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Column(
              children: [
                Text('Photo Printer 80mm', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Bluetooth thermal printing', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          body: pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.print_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.bluetooth), label: 'Printers'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            ],
          ),
        );
      },
    );
  }
}
