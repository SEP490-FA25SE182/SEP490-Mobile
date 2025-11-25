import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _handled = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final code = cap.barcodes.firstOrNull?.rawValue ?? '';
    if (code.isEmpty) return;
    _handled = true;
    // Điều hướng thẳng sang Unity
    context.go(Uri(path: '/unity-test', queryParameters: {'code': code}).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Quét mã'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _ctrl.switchCamera(),
            tooltip: 'Đổi camera',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _ctrl.toggleTorch(),
            tooltip: 'Bật/tắt đèn',
          ),
        ],
      ),
      body: Positioned.fill(
        child: MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
