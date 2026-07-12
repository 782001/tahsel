import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_constants.dart';

import '../utils/assets.dart';

class ReceiptImageService {
  static const double _width = 1080;
  static const double _height = 1500;

  static const Color _primary = Color(0xFF1E56A0);
  static const Color _primaryDark = Color(0xFF005DB7);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFD32F2F);

  // دالة رئيسية لإنشاء وحفظ الصورة (يمكنك استدعاؤها من الخارج)
  static Future<File> generateReceipt({
    required String customerName,
    required double paid,
    required double total,
    required double remaining,
    required bool isArabic,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _width, _height));

    // 1. رسم الخلفية المندمجة
    _drawBackground(canvas);

    // 2. تحميل اللوجو ورسم الهيدر
    ui.Image? logo;
    try {
      logo = await _loadLogo();
    } catch (e) {
      // إذا فشل تحميل اللوجو لا تتوقف العملية
    }

    _drawHeader(canvas, logo, isArabic);

    // 3. رسم الكارت الرئيسي المنبثق (بظل ناعم)
    _drawMainCard(canvas);

    // 4. رسم بيانات العميل والمبالغ الماليّة بالاتجاه الصحيح
    _drawCustomerData(
      canvas,
      customerName: customerName,
      paid: paid,
      total: total,
      remaining: remaining,
      isArabic: isArabic,
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
      targetWidth: 140, // حجم مناسب ومتناسق داخل الدائرة
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawBackground(Canvas canvas) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, _height),
        const [Color(0xffFDFDFD), Color(0xffF2F6FA)],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, _width, _height), paint);
  }

  static void _drawHeader(Canvas canvas, ui.Image? logo, bool isArabic) {
    final headerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(60, 60, _width - 120, 280),
      const Radius.elliptical(32, 32),
    );

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(60, 60),
        const Offset(_width - 60, 340),
        const [_primary, _primaryDark],
      );

    canvas.drawRRect(headerRect, paint);

    // دوائر ديكورية خلفية خفيفة جداً
    canvas.drawCircle(
      const Offset(980, 40),
      160,
      Paint()..color = Colors.white.withValues(alpha: .06),
    );

    canvas.drawCircle(
      const Offset(100, 300),
      120,
      Paint()..color = Colors.white.withValues(alpha: .04),
    );

    // رسم اللوجو إذا توفر بشكل احترافي ومحاذاته بالمنتصف
    if (logo != null) {
      final double avatarCenterX = _width / 2;
      final double avatarCenterY = 135;
      final double radius = 55;

      canvas.drawCircle(
        Offset(avatarCenterX, avatarCenterY),
        radius,
        Paint()..color = Colors.white,
      );

      final dstRect = Rect.fromCircle(
        center: Offset(avatarCenterX, avatarCenterY),
        radius: radius - 8,
      );
      final srcRect = Rect.fromLTWH(
        0,
        0,
        logo.width.toDouble(),
        logo.height.toDouble(),
      );
      canvas.drawImageRect(logo, srcRect, dstRect, Paint());
    }

    // عنوان الإيصال الرئيسي
    _drawCenteredText(
      canvas,
      text: isArabic ? "إيصال تحصيل نقدية" : "Payment Receipt",
      y: 220,
      size: 44,
      color: Colors.white,
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    // التاريخ والوقت الحالي
    final dateStr = DateFormat(
      isArabic ? "dd MMMM yyyy - hh:mm a" : "MMM dd, yyyy - hh:mm a",
      isArabic ? "ar" : "en",
    ).format(DateTime.now());

    _drawCenteredText(
      canvas,
      text: dateStr,
      y: 280,
      size: 24,
      color: Colors.white70,
      weight: FontWeight.normal,
      isArabic: isArabic,
    );
  }

  static void _drawMainCard(Canvas canvas) {
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(60, 340, _width - 120, 1100),
      const Radius.elliptical(32, 32),
    );

    // ظل ناعم واحترافي للكارت السفلي
    canvas.drawShadow(
      Path()..addRRect(card),
      Colors.blueGrey.withValues(alpha: .12),
      20,
      true,
    );

    canvas.drawRRect(card, Paint()..color = Colors.white);
  }

  static void _drawCustomerData(
    Canvas canvas, {
    required String customerName,
    required double paid,
    required double total,
    required double remaining,
    required bool isArabic,
  }) {
    // اسم العميل
    _drawCenteredText(
      canvas,
      text: customerName,
      y: 410,
      size: 46,
      color: const Color(0xFF263238),
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    // تسمية نوع الكارت (عميل)
    _drawCenteredText(
      canvas,
      text: isArabic ? "اسم العميل" : "Customer Name",
      y: 475,
      size: 24,
      color: Colors.grey.shade500,
      weight: FontWeight.w500,
      isArabic: isArabic,
    );

    // خط فاصل أنيق
    final dividerPaint = Paint()
      ..color = Colors.grey.withValues(alpha: .12)
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(140, 540),
      const Offset(940, 540),
      dividerPaint,
    );

    // كروت المبالغ المالية (تدعم الـ RTL والـ LTR بشكل ديناميكي)
    _drawFinancialRow(
      canvas,
      y: 590,
      title: isArabic ? "المبلغ المدفوع" : "Paid Amount",
      value: paid,
      color: _primary,
      icon: Icons.payments_rounded,
      isArabic: isArabic,
    );

    _drawFinancialRow(
      canvas,
      y: 780,
      title: isArabic ? "إجمالي الحساب" : "Total Debt",
      value: total,
      color: _warning,
      icon: Icons.account_balance_wallet_rounded,
      isArabic: isArabic,
    );

    _drawFinancialRow(
      canvas,
      y: 970,
      title: isArabic ? "المتبقي" : "Remaining Amount",
      value: remaining,
      color: remaining <= 0 ? _success : _danger,
      icon: remaining <= 0
          ? Icons.check_circle_rounded
          : Icons.pending_actions_rounded,
      isArabic: isArabic,
    );
    _drawCenteredText(
      canvas,
      text: isArabic ? "شكراً لثقتكم بنا ❤️" : "Thank you for your trust ❤️",
      y: 1185,
      size: 28,
      color: _primaryDark,
      weight: FontWeight.bold,
      isArabic: isArabic,
    );

    _drawCenteredText(
      canvas,
      text: isArabic
          ? "تم إنشاء هذا الإيصال بواسطة تطبيق تحصيل"
          : "Generated by Tahsel App",
      y: 1235,
      size: 22,
      color: Colors.grey.shade700,
      weight: FontWeight.w600,
      isArabic: isArabic,
    );

    _drawCenteredText(
      canvas,
      text: isArabic
          ? "إدارة العملاء • متابعة الديون • إدارة الموظفين"
          : "Customers • Debts • Employee Management",
      y: 1275,
      size: 20,
      color: Colors.grey.shade500,
      weight: FontWeight.normal,
      isArabic: isArabic,
    );
  }

  static void _drawFinancialRow(
    Canvas canvas, {
    required double y,
    required String title,
    required double value,
    required Color color,
    required IconData icon,
    required bool isArabic,
  }) {
    const double leftMargin = 120;
    const double cardWidth = 840;
    const double cardHeight = 150;

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        leftMargin,
        0,
        cardWidth,
        cardHeight,
      ).shift(Offset(0, y)),
      const Radius.circular(20),
    );

    // خلفية الكارت الشفافة باللون المخصص
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: .06));

    // حواف الكارت الناعمة
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: .15),
    );

    // شريط ملون جانبي جمالي (يتحرك حسب لغة الإيصال يمين/يسار)
    final double stripX = isArabic ? (leftMargin + cardWidth - 12) : leftMargin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stripX, y, 12, cardHeight),
        const Radius.circular(12),
      ),
      Paint()..color = color,
    );

    // حساب أماكن الأيقونات والنصوص بناءً على اتجاه اللغة (RTL / LTR)
    final double iconX = isArabic
        ? (leftMargin + cardWidth - 85)
        : (leftMargin + 40);
    final double textX = isArabic
        ? (leftMargin + cardWidth - 110)
        : (leftMargin + 115);
    final double priceX = isArabic
        ? (leftMargin + 40)
        : (leftMargin + cardWidth - 40);

    // رسم الأيقونة
    final iconPainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 38,
          color: color,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(iconX, y + (cardHeight - iconPainter.height) / 2),
    );

    // رسم عنوان الحقل (مثال: المبلغ المدفوع)
    final titlePainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 28,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: 400);
    titlePainter.paint(
      canvas,
      Offset(isArabic ? textX - titlePainter.width : textX, y + 30),
    );

    // رسم القيمة المالية بجانب العنوان أو بالجهة المقابلة
    final currency = isArabic ? "ج.م" : "EGP";
    final valuePainter = TextPainter(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      text: TextSpan(
        text: "${value.toSmartAmount()} $currency",
        style: const TextStyle(
          fontSize: 34,
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.bold,
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: 350);
    valuePainter.paint(
      canvas,
      Offset(isArabic ? priceX : priceX - valuePainter.width, y + 78),
    );
  }

  static void _drawCenteredText(
    Canvas canvas, {
    required String text,
    required double y,
    required double size,
    required Color color,
    required FontWeight weight,
    required bool isArabic,
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
          fontFamily: AppConstants.fontFamily,
        ),
      ),
    )..layout(maxWidth: _width);

    painter.paint(canvas, Offset((_width - painter.width) / 2, y));
  }
}
