import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/printer_device.dart';
import '../widgets/status_pill.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.permissionsGranted,
    required this.selectedImage,
    required this.connectedPrinter,
    required this.lastError,
    required this.busy,
    required this.onPickImage,
    required this.onPrintImage,
    required this.onPrintTest,
  });

  final bool permissionsGranted;
  final XFile? selectedImage;
  final PrinterDevice? connectedPrinter;
  final String? lastError;
  final bool busy;
  final VoidCallback onPickImage;
  final VoidCallback onPrintImage;
  final VoidCallback onPrintTest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroPrinterCard(
          permissionsGranted: permissionsGranted,
          connectedPrinter: connectedPrinter,
        ),
        const SizedBox(height: 16),
        _SelectedPhotoCard(
          selectedImage: selectedImage,
          busy: busy,
          onPickImage: onPickImage,
          onPrintImage: onPrintImage,
          onPrintTest: onPrintTest,
        ),
        const SizedBox(height: 16),
        _PrinterStatusCard(
          connectedPrinter: connectedPrinter,
          lastError: lastError,
        ),
      ],
    );
  }
}

class _HeroPrinterCard extends StatelessWidget {
  const _HeroPrinterCard({
    required this.permissionsGranted,
    required this.connectedPrinter,
  });

  final bool permissionsGranted;
  final PrinterDevice? connectedPrinter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Print photos beautifully on 80mm paper',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            permissionsGranted
                ? 'Choose one photo, connect your paired printer, then print.'
                : 'Grant Bluetooth permission first.',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              StatusPill(label: connectedPrinter != null ? 'Connected' : 'Not connected'),
              const StatusPill(label: '80mm'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedPhotoCard extends StatelessWidget {
  const _SelectedPhotoCard({
    required this.selectedImage,
    required this.busy,
    required this.onPickImage,
    required this.onPrintImage,
    required this.onPrintTest,
  });

  final XFile? selectedImage;
  final bool busy;
  final VoidCallback onPickImage;
  final VoidCallback onPrintImage;
  final VoidCallback onPrintTest;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected photo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(selectedImage!.path),
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const _EmptyPhotoPlaceholder(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onPickImage,
                    icon: const Icon(Icons.collections_outlined),
                    label: const Text('Choose photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onPrintImage,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print 80mm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onPrintTest,
                child: const Text('Print test page'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhotoPlaceholder extends StatelessWidget {
  const _EmptyPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined, size: 42, color: Color(0xFF2563EB)),
          SizedBox(height: 8),
          Text('No photo selected', style: TextStyle(fontWeight: FontWeight.w600)),
          Text('Tap the button below to choose one image'),
        ],
      ),
    );
  }
}

class _PrinterStatusCard extends StatelessWidget {
  const _PrinterStatusCard({required this.connectedPrinter, required this.lastError});

  final PrinterDevice? connectedPrinter;
  final String? lastError;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(connectedPrinter?.name ?? 'No printer connected'),
            Text(connectedPrinter?.address ?? 'Open the Printers tab to connect to a paired Bluetooth printer.'),
            if (lastError != null) ...[
              const SizedBox(height: 8),
              Text('Last issue: $lastError', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
