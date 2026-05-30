import 'package:flutter/material.dart';

import '../screens/printer_home_page.dart';

class WoosimPrinterApp extends StatelessWidget {
  const WoosimPrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Printer 80mm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AB4F8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PrinterHomePage(),
    );
  }
}
