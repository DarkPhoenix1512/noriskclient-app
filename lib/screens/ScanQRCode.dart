import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/widgets/QRScannerOverlayShape.dart';

class ScanQRCode extends StatefulWidget {
  const ScanQRCode({super.key, required this.redeem});

  final Function(String username) redeem;

  @override
  _ScanQRCodeState createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<ScanQRCode> {
  MobileScannerController controller = MobileScannerController();
  int? lastRedeem;
  bool _scannerClosed = false;

  Future<void> _closeScanner() async {
    if (_scannerClosed) return;
    _scannerClosed = true;
    try {
      await controller.stop();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    controller.start();
    lastRedeem = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void dispose() {
    _closeScanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: NoRiskClientColors.background,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: MobileScanner(
              fit: BoxFit.fitHeight,
              controller: controller,
              onDetect: (BarcodeCapture result) {
                handleQrCodeResult(
                    controller, result.barcodes[0].rawValue ?? '');
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: NoRiskClientColors.light,
                  borderRadius: 10,
                  borderLength: 15,
                  borderWidth: 7.5,
                  cutOutSize: MediaQuery.of(context).size.width / 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 40),
            child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                    onPressed: () {
                      _closeScanner();
                      if (mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 30))),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                  onPressed: () async {
                    await controller.toggleTorch();
                  },
                  icon: const Icon(Icons.flash_on_rounded,
                      color: Colors.white, size: 50)),
            ),
          ),
        ],
      ),
    );
  }

  void handleQrCodeResult(
      MobileScannerController controller, String code) async {
    print('QR Code Detected: $code');

    if (code.contains("NRC-GAMESCOM-2026-")) {
      String targetUsername = code.replaceFirst('NRC-GAMESCOM-2026-', '');

      await _closeScanner();

      if (lastRedeem! + 1000 >= DateTime.now().millisecondsSinceEpoch) {
        return;
      }

      widget.redeem(targetUsername);

      lastRedeem = DateTime.now().millisecondsSinceEpoch;
    }
  }
}
