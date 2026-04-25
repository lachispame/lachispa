import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_tokens.dart';

class _QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderOffset
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    // Draw background
    canvas.saveLayer(
      rect,
      backgroundPaint,
    );
    canvas.drawRect(rect, backgroundPaint);

    // Draw cutout
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cutOutRect,
        Radius.circular(borderRadius),
      ),
      boxPaint,
    );
    canvas.restore();

    // Draw border lines
    final path = Path();

    // Top left
    path.moveTo(cutOutRect.left - borderOffset, cutOutRect.top + _borderLength);
    path.lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius);
    path.quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
        cutOutRect.left + borderRadius, cutOutRect.top - borderOffset);
    path.lineTo(cutOutRect.left + _borderLength, cutOutRect.top - borderOffset);

    // Top right
    path.moveTo(cutOutRect.right - _borderLength, cutOutRect.top - borderOffset);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset);
    path.quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
        cutOutRect.right + borderOffset, cutOutRect.top + borderRadius);
    path.lineTo(cutOutRect.right + borderOffset, cutOutRect.top + _borderLength);

    // Bottom right
    path.moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - _borderLength);
    path.lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius);
    path.quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
        cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset);
    path.lineTo(cutOutRect.right - _borderLength, cutOutRect.bottom + borderOffset);

    // Bottom left
    path.moveTo(cutOutRect.left + _borderLength, cutOutRect.bottom + borderOffset);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset);
    path.quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
        cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius);
    path.lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - _borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScanned;
  
  const QRScannerWidget({
    super.key,
    required this.onScanned,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController controller;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!hasScanned && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        hasScanned = true;
        controller.stop();
        widget.onScanned(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Stack(
        children: [
          // QR Scanner with overlay
          Stack(
            children: [
              MobileScanner(
                controller: controller,
                onDetect: _onDetect,
              ),
              // Overlay personalizado
              Container(
                decoration: ShapeDecoration(
                  shape: _QrScannerOverlayShape(
                    borderColor: t.accentSolid,
                    borderRadius: 16,
                    borderLength: 30,
                    borderWidth: 4,
                    cutOutSize: 300,
                  ),
                ),
              ),
            ],
          ),

          // Header with gradient background
          Container(
            height: 120,
            decoration: BoxDecoration(
              // Dark scrim is intrinsic to the camera-overlay UX
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    // Back button (semi-transparent over camera)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.textPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: t.textPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: t.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Title
                    Text(
                      'Escanear QR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                // Dark scrim is intrinsic to the camera-overlay UX
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.textPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: t.textPrimary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Point the camera at the QR code\nto scan the invoice or address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: t.textPrimary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Camera controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: t.textPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: t.textPrimary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.flash_on,
                            color: t.textPrimary,
                            size: 24,
                          ),
                          onPressed: () async {
                            await controller.toggleTorch();
                          },
                        ),
                      ),

                      // Switch camera button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: t.textPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: t.textPrimary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.flip_camera_ios,
                            color: t.textPrimary,
                            size: 24,
                          ),
                          onPressed: () async {
                            await controller.switchCamera();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}