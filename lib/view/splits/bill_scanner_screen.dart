import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';

class BillScanResult {
  final String? title;
  final String? amount;
  final String? notes;
  const BillScanResult({this.title, this.amount, this.notes});
}

class BillScannerScreen extends StatefulWidget {
  const BillScannerScreen({super.key});

  @override
  State<BillScannerScreen> createState() => _BillScannerScreenState();
}

class _BillScannerScreenState extends State<BillScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _detected = false;
  bool _torchOn = false;
  bool _analyzing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _detected = true;
    HapticFeedback.mediumImpact();
    final result = _parse(raw);
    _ctrl.stop().then((_) => Get.back(result: result));
  }

  Future<void> _pickFromGallery() async {
    if (_analyzing) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _analyzing = true);
    final capture = await _ctrl.analyzeImage(file.path);
    setState(() => _analyzing = false);
    final raw = capture?.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in that image')),
        );
      }
      return;
    }
    _detected = true;
    HapticFeedback.mediumImpact();
    await _ctrl.stop();
    Get.back(result: _parse(raw));
  }

  // Strips trailing zeros: "68.000" → "68", "68.50" → "68.5"
  String? _cleanAmount(String? raw) {
    if (raw == null) return null;
    final n = double.tryParse(raw);
    if (n == null) return null;
    return n == n.truncateToDouble()
        ? n.toInt().toString()
        : n.toString();
  }

  BillScanResult _parse(String raw) {
    debugPrint('[BillScanner] raw: $raw');

    // ── UPI QR: upi://pay?pa=...&pn=Name&am=100&tn=Note ──────────────────────
    if (raw.startsWith('upi://')) {
      try {
        final uri = Uri.parse(raw);
        final p = uri.queryParameters;

        // Prefer invoiceValue over am — many merchant QRs set am=0
        // and put the real total in invoiceValue
        String? amount = _cleanAmount(p['invoiceValue']);
        if (amount == null || amount == '0') {
          amount = _cleanAmount(p['am'] ?? p['amount']);
        }
        if (amount == '0') amount = null;

        // tn is often a raw reference like "payOD123..." — skip it if it
        // looks like a reference ID; prefer invoiceNo as notes
        final tn = p['tn'];
        final notes = p['invoiceNo'] ??
            (tn != null && !RegExp(r'^pay[A-Z0-9]+$').hasMatch(tn) ? tn : null);

        return BillScanResult(
          title: p['pn'] ?? p['merchant-name'],
          amount: amount,
          notes: notes,
        );
      } catch (_) {}
    }

    // ── URL with amount params (e.g. https://pay.app/bill?amount=500) ─────────
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      try {
        final uri = Uri.parse(raw);
        final p = uri.queryParameters;
        final amount = p['amount'] ?? p['amt'] ?? p['total'] ?? p['am'];
        final title = p['merchant'] ?? p['name'] ?? p['pn'] ?? p['shop'];
        if (amount != null || title != null) {
          return BillScanResult(title: title, amount: amount, notes: p['note'] ?? p['tn']);
        }
      } catch (_) {}
    }

    // ── JSON payload ─────────────────────────────────────────────────────────
    if (raw.trimLeft().startsWith('{')) {
      try {
        // Manual key search without dart:convert to keep it simple
        final amountMatch = RegExp(r'"(?:amount|total|amt|grand_total)"\s*:\s*"?(\d+\.?\d*)"?', caseSensitive: false).firstMatch(raw);
        final nameMatch = RegExp(r'"(?:merchant|name|restaurant|shop|pn)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(raw);
        if (amountMatch != null || nameMatch != null) {
          return BillScanResult(
            title: nameMatch?.group(1),
            amount: amountMatch?.group(1),
          );
        }
      } catch (_) {}
    }

    // ── Last resort: regex scan for a currency amount anywhere in the string ──
    final amountMatch = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+\.?\d{0,2})', caseSensitive: false).firstMatch(raw);
    if (amountMatch != null) {
      return BillScanResult(amount: amountMatch.group(1), title: raw.length > 60 ? raw.substring(0, 60) : raw);
    }

    // Generic fallback
    return BillScanResult(title: raw.length > 60 ? raw.substring(0, 60) : raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ────────────────────────────────────────────────
          MobileScanner(controller: _ctrl, onDetect: _onDetect),

          // ── Scrim + viewfinder ────────────────────────────────────────────
          _ScanOverlay(),

          // ── Top bar ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const PhosphorIcon(
                          PhosphorIconsLight.arrowLeft,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => _ctrl.stop().then((_) => Get.back()),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: PhosphorIcon(
                          _torchOn
                              ? PhosphorIconsFill.flashlight
                              : PhosphorIconsLight.flashlight,
                          color: _torchOn ? Colors.yellow : Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          _ctrl.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scan Bill QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Point the camera at a QR code or barcode on your bill',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom actions ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gallery button
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: _analyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PhosphorIcon(
                                PhosphorIconsLight.image,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upload from gallery',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                // Hint pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsLight.qrCode,
                          color: AppColor.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'UPI QR codes pre-fill amount & payee',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay with cutout ───────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height * 0.48;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: boxSize, height: boxSize);

    // Darken everything outside the box
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      scrim,
    );

    // Corner brackets
    const corner = 28.0;
    const stroke = 3.5;
    final paint = Paint()
      ..color = AppColor.primary
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // top-left
      [rect.topLeft, Offset(rect.left + corner, rect.top),
          Offset(rect.left, rect.top + corner)],
      // top-right
      [rect.topRight, Offset(rect.right - corner, rect.top),
          Offset(rect.right, rect.top + corner)],
      // bottom-left
      [rect.bottomLeft, Offset(rect.left + corner, rect.bottom),
          Offset(rect.left, rect.bottom - corner)],
      // bottom-right
      [rect.bottomRight, Offset(rect.right - corner, rect.bottom),
          Offset(rect.right, rect.bottom - corner)],
    ];

    for (final c in corners) {
      canvas.drawLine(c[1], c[0], paint);
      canvas.drawLine(c[0], c[2], paint);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}
