import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanning = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование чека'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanning && mounted) {
            _isScanning = false;
            final qrData = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
            if (qrData != null) {
              Navigator.pop(context, qrData);
            }
          }
        },
      ),
    );
  }
}