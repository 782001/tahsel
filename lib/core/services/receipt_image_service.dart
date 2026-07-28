import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_constants.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../utils/assets.dart';

class ReceiptImageService {
  static const double _width = 1080;
  static const double _height = 1600;

  static const Color _primary = Color(0xFF1E56A0);
  static const Color _primaryDark = Color(0xFF061A35);

  // دالة رئيسية لإنشاء وحفظ الصورة (يمكنك استدعاؤها من الخارج)
  static Future<File> generateReceipt({
    required String customerName,
    required double paid,
    required double total,
    required double remaining,
    required bool isArabic,
    bool isCustomerReceipt = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _width, _height));

    // 1. رسم الخلفية العميقة بلون التطبيق الأساسي مع تأثيرات
    _drawBackground(canvas);

    // 2. تحميل اللوجو
    ui.Image? logo;
    try {
      logo = await _loadLogo();
    } catch (e) {
      // إذا فشل تحميل اللوجو لا تتوقف العملية
    }

    // 3. رسم الكارت الرئيسي الزجاجي (Glassmorphism)
    _drawMainCard(canvas);

    // 4. رسم الهيدر
    _drawHeader(canvas, isArabic, isCustomerReceipt);

    // 5. رسم اللوجو أعلى الكارت
    _drawLogo(canvas, logo);

    // 6. رسم بيانات العميل والمبالغ الماليّة
    _drawCustomerData(
      canvas,
      customerName: customerName,
      paid: paid,
      total: total,
      remaining: remaining,
      isArabic: isArabic,
      isCustomerReceipt: isCustomerReceipt,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(_width.toInt(), _height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(buffer);

    return file;
  }

  static Future<ui.Image> _loadLogo() async {
    final data = await rootBundle.load(Assets.imagesAppLogo);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 140,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawBackground(Canvas canvas) {
    // Rich Tahsel Blue Gradient
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(_width, _height),
        [_primary, _primaryDark],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, _width, _height), paint);

    // Decorative Texture 1: Glowing orbs
    canvas.drawCircle(
      const Offset(100, 200),
      400,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(100, 200), 400, [
          const Color(0xFF3B82F6).withValues(alpha: 0.15),
          Colors.transparent,
        ]),
    );
    canvas.drawCircle(
      const Offset(980, 1300),
      500,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(980, 1300), 500, [
          const Color(0xFF0EA5E9).withValues(alpha: 0.12),
          Colors.transparent,
        ]),
    );

    // Decorative Texture 2: Grid Lines (Blueprint feel)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    for (double i = 0; i < _width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, _height), gridPaint);
    }
    for (double i = 0; i < _height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(_width, i), gridPaint);
    }

    // Decorative Texture 3: Abstract top wave
    final wavePath = Path();
    wavePath.moveTo(0, 0);
    wavePath.lineTo(_width, 0);
    wavePath.lineTo(_width, 300);
    wavePath.quadraticBezierTo(_width * 0.75, 400, _width * 0.5, 250);
    wavePath.quadraticBezierTo(_width * 0.25, 100, 0, 200);
    wavePath.close();

    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(0, 400),
          [Colors.white.withValues(alpha: 0.06), Colors.transparent],
        ),
    );
  }

  static void _drawMainCard(Canvas canvas) {
    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(60, 180, _width - 120, 1300),
      const Radius.circular(40),
    );

    // Dark shadow for depth
    canvas.drawShadow(
      Path()..addRRect(cardRect),
      Colors.black.withValues(alpha: 0.4),
      40,
      true,
    );

    // Glass background
    canvas.drawRRect(
      cardRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(60, 180),
          const Offset(60, 1480),
          [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
    );

    // Glass Border
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = ui.Gradient.linear(
          const Offset(60, 180),
          const Offset(_width - 60, 1480),
          [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
    );
  }

  static void _drawHeader(Canvas canvas, bool isArabic, bool isCustomerReceipt) {
    // Receipt Title
    _drawCenteredText(
      canvas,
      text: isArabic
          ? (isCustomerReceipt ? "إيصال تحصيل نقدية" : "إيصال سداد نقدية")
          : (isCustomerReceipt ? "Collection Receipt" : "Payment Receipt"),
      y: 290,
      size: 42,
      color: Colors.white,
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    // Date
    final dateStr = DateFormat(
      isArabic ? "dd MMMM yyyy - hh:mm a" : "MMM dd, yyyy - hh:mm a",
      isArabic ? "ar" : "en",
    ).format(DateTime.now());

    _drawCenteredText(
      canvas,
      text: dateStr,
      y: 350,
      size: 22,
      color: Colors.white.withValues(alpha: 0.7),
      weight: FontWeight.w500,
      isArabic: isArabic,
    );
  }

  static void _drawLogo(Canvas canvas, ui.Image? logo) {
    final double centerX = _width / 2;
    final double centerY = 180; // Exactly on the top edge of the card
    final double radius = 75;

    // Glowing shadow for logo
    canvas.drawShadow(
      Path()..addOval(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      ),
      const Color(0xFFF59E0B),
      20,
      true,
    );

    // Golden ring border
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 4,
      Paint()..color = const Color(0xFFF59E0B),
    );

    // White circle background for logo
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()..color = Colors.white,
    );

    if (logo != null) {
      final dstRect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius - 10,
      );
      final srcRect = Rect.fromLTWH(
        0,
        0,
        logo.width.toDouble(),
        logo.height.toDouble(),
      );
      canvas.drawImageRect(
        logo,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
  }

  static void _drawCustomerData(
    Canvas canvas, {
    required String customerName,
    required double paid,
    required double total,
    required double remaining,
    required bool isArabic,
    required bool isCustomerReceipt,
  }) {
    // "Customer Name" Label
    _drawCenteredText(
      canvas,
      text: isArabic 
          ? (isCustomerReceipt ? "اسم العميل" : "اسم المورد / الدائن") 
          : (isCustomerReceipt ? "Customer Name" : "Supplier Name"),
      y: 440,
      size: 22,
      color: Colors.white.withValues(alpha: 0.6),
      weight: FontWeight.w500,
      isArabic: isArabic,
      letterSpacing: 1.5,
    );

    // Customer Name Value
    _drawCenteredText(
      canvas,
      text: customerName,
      y: 480,
      size: 46,
      color: Colors.white,
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    // Dashed divider
    _drawDashedLine(
      canvas,
      p1: const Offset(120, 590),
      p2: const Offset(_width - 120, 590),
      color: Colors.white.withValues(alpha: 0.2),
      dashWidth: 10,
      dashSpace: 8,
    );

    // Financial Rows
    _drawFinancialRow(
      canvas,
      y: 650,
      title: isArabic ? "المبلغ المدفوع" : "Paid Amount",
      value: paid,
      gradientColors: const [
        Color(0xFF60A5FA),
        Color(0xFF2563EB),
      ], // Vibrant Blue
      icon: Icons.payments_rounded,
      isArabic: isArabic,
    );

    _drawFinancialRow(
      canvas,
      y: 810,
      title: isArabic ? "إجمالي الحساب" : "Total Debt",
      value: total,
      gradientColors: const [
        Color(0xFFFBBF24),
        Color(0xFFD97706),
      ], // Vibrant Amber
      icon: Icons.account_balance_wallet_rounded,
      isArabic: isArabic,
    );

    final isPaidFull = remaining <= 0.01;
    _drawFinancialRow(
      canvas,
      y: 970,
      title: isArabic ? "المتبقي" : "Remaining Amount",
      value: remaining,
      gradientColors: isPaidFull
          ? const [Color(0xFF34D399), Color(0xFF059669)] // Vibrant Emerald
          : const [Color(0xFFF87171), Color(0xFFDC2626)], // Vibrant Red
      icon: isPaidFull
          ? Icons.check_circle_rounded
          : Icons.pending_actions_rounded,
      isArabic: isArabic,
    );

    // Add a PAID stamp if remaining is 0
    if (isPaidFull) {
      _drawStamp(canvas, text: isArabic ? "خالص" : "PAID", isArabic: isArabic);
    }

    // Footer lines
    _drawDashedLine(
      canvas,
      p1: const Offset(120, 1150),
      p2: const Offset(_width - 120, 1150),
      color: Colors.white.withValues(alpha: 0.2),
      dashWidth: 10,
      dashSpace: 8,
    );

    _drawCenteredText(
      canvas,
      text: isArabic ? "شكراً لثقتكم بنا ❤️" : "Thank you for your trust ❤️",
      y: 1220,
      size: 30,
      color: Colors.white,
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    _drawCenteredText(
      canvas,
      text: isArabic
          ? "إدارة العملاء • متابعة الديون • إدارة الموظفين"
          : "Customers • Debts • Employee Management",
      y: 1280,
      size: 20,
      color: Colors.white.withValues(alpha: 0.6),
      weight: FontWeight.w500,
      isArabic: isArabic,
    );

    // Outside the card
    _drawCenteredText(
      canvas,
      text: isArabic
          ? "تم إنشاء هذا الإيصال بواسطة تطبيق تحصيل"
          : "Generated by Tahsel App",
      y: 1520,
      size: 22,
      color: Colors.white.withValues(alpha: 0.5),
      weight: FontWeight.w600,
      isArabic: isArabic,
    );
  }

  static void _drawFinancialRow(
    Canvas canvas, {
    required double y,
    required String title,
    required double value,
    required List<Color> gradientColors,
    required IconData icon,
    required bool isArabic,
  }) {
    const double leftMargin = 100;
    const double cardWidth = 880;
    const double cardHeight = 130;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftMargin, y, cardWidth, cardHeight),
      const Radius.circular(24),
    );

    // Dark semi-transparent background for contrast
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    // Colored subtle border
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = gradientColors.first.withValues(alpha: 0.5),
    );

    // Colored gradient strip on the edge
    final double stripX = isArabic ? (leftMargin + cardWidth - 8) : leftMargin;
    final stripRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(stripX, y, 8, cardHeight),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      stripRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(stripX, y),
          Offset(stripX, y + cardHeight),
          gradientColors,
        ),
    );

    // Icon in a gradient circle with glow
    final double iconCenterX = isArabic
        ? (leftMargin + cardWidth - 65)
        : (leftMargin + 65);
    final double iconCenterY = y + cardHeight / 2;

    // Glow
    canvas.drawCircle(
      Offset(iconCenterX, iconCenterY),
      32,
      Paint()
        ..shader = ui.Gradient.radial(Offset(iconCenterX, iconCenterY), 32, [
          gradientColors.first.withValues(alpha: 0.6),
          Colors.transparent,
        ]),
    );

    canvas.drawCircle(
      Offset(iconCenterX, iconCenterY),
      28,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(iconCenterX - 28, iconCenterY - 28),
          Offset(iconCenterX + 28, iconCenterY + 28),
          gradientColors,
        ),
    );

    // Icon (White)
    final iconPainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 26,
          color: Colors.white,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        iconCenterX - iconPainter.width / 2,
        iconCenterY - iconPainter.height / 2,
      ),
    );

    // Title
    final double textX = isArabic
        ? (leftMargin + cardWidth - 115)
        : (leftMargin + 115);

    final titlePainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
          fontSize: 26,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: 300);
    titlePainter.paint(
      canvas,
      Offset(
        isArabic ? textX - titlePainter.width : textX,
        y + (cardHeight - titlePainter.height) / 2,
      ),
    );

    // Currency and Value
    final currency = AppStrings.currencyEgp.tr();
    final valuePainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: "${value.toSmartAmount()} $currency",
        style: const TextStyle(
          fontSize: 34,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: 400);

    final double priceX = isArabic
        ? (leftMargin + 40)
        : (leftMargin + cardWidth - 40);

    valuePainter.paint(
      canvas,
      Offset(
        isArabic ? priceX : priceX - valuePainter.width,
        y + (cardHeight - valuePainter.height) / 2,
      ),
    );
  }

  static void _drawDashedLine(
    Canvas canvas, {
    required Offset p1,
    required Offset p2,
    required Color color,
    required double dashWidth,
    required double dashSpace,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final distance = (p2 - p1).distance;
    final direction = (p2 - p1) / distance;

    double drawnLength = 0.0;
    while (drawnLength < distance) {
      final currentP1 = p1 + direction * drawnLength;
      final currentP2 =
          p1 + direction * math.min(drawnLength + dashWidth, distance);
      canvas.drawLine(currentP1, currentP2, paint);
      drawnLength += dashWidth + dashSpace;
    }
  }

  static void _drawStamp(
    Canvas canvas, {
    required String text,
    required bool isArabic,
  }) {
    canvas.save();

    // Position of the stamp
    final double stampX = isArabic ? 240 : _width - 240;
    final double stampY = 600;

    // Rotate canvas slightly for a realistic stamp effect
    canvas.translate(stampX, stampY);
    canvas.rotate(-0.15); // slight tilt

    final paint = Paint()
      ..color =
          const Color(0xFF34D399) // Brighter Emerald for dark bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-85, -40, 170, 80),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, paint);

    final textPainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF34D399),
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: 6.0,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  static void _drawCenteredText(
    Canvas canvas, {
    required String text,
    required double y,
    required double size,
    required Color color,
    required FontWeight weight,
    required bool isArabic,
    double? letterSpacing,
  }) {
    final painter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: _width);

    painter.paint(canvas, Offset((_width - painter.width) / 2, y));
  }
}
