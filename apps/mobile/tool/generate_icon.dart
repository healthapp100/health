// One-off icon generator — NOT a real test. Run with `flutter test tool/generate_icon.dart`.
// Renders the app's brand mark (AppTheme.primary teal-green square, white rounded cross, a small
// pulse-line accent) to a 1024x1024 PNG via a RepaintBoundary capture, since this environment has
// no image-editing tool available to hand-author one. flutter_launcher_icons/flutter_native_splash
// then resize this single source image to every platform's required icon/splash sizes.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_platform/core/theme/app_theme.dart';

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(1024, 1024),
      painter: _BrandMarkPainter(),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bgPaint = Paint()..color = AppTheme.primary;
    // Full-bleed square, deliberately NOT pre-rounded — Android's adaptive-icon mask and iOS's
    // own corner rounding both apply their own shape at install time; a source image that's
    // already rounded would double up and leave a visible seam inside their mask.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, w), bgPaint);

    // A rounded plus/cross — the one health-symbol shape recognizable at any size, including a
    // 48x48 launcher icon where finer detail (a heartbeat line, a stethoscope) would just blur.
    final crossPaint = Paint()..color = Colors.white;
    final armLength = w * 0.46;
    final armThickness = w * 0.16;
    final center = Offset(w / 2, w / 2);
    final radius = armThickness * 0.4;

    final vertical = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: armThickness, height: armLength),
      Radius.circular(radius),
    );
    final horizontal = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: armLength, height: armThickness),
      Radius.circular(radius),
    );
    canvas.drawRRect(vertical, crossPaint);
    canvas.drawRRect(horizontal, crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('generate icon', (tester) async {
    // Without this, the root gets the default 800x600 test-surface constraints and CustomPaint's
    // requested Size(1024, 1024) is ignored (it only applies under loose/unconstrained parents) —
    // the captured image comes out squashed to 800x600 instead of the intended square.
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _BrandMark(),
        ),
      ),
    );
    await tester.pump();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    await tester.runAsync(() async {
      final dir = Directory('assets/icon');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('assets/icon/icon.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      // Splash uses the same mark but the OS clips corners itself, so a plain square (no
      // pre-rounded corners) avoids compounding the rounding twice.
    });
  });
}
