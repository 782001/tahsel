import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tahsel/core/services/logo/project_logo_service.dart';
import 'package:tahsel/core/utils/assets.dart';

/// In-memory cache for PDF fonts and assets to ensure sub-millisecond generation
class PdfAssetCache {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static Uint8List? _logoBytes;
  static pw.MemoryImage? _logoImage;

  /// Loads and caches the regular Arabic/English font
  static Future<pw.Font> getRegularFont() async {
    if (_regularFont != null) return _regularFont!;
    final data = await rootBundle.load('assets/fonts/DGAgnadeen-Regular.ttf');
    _regularFont = pw.Font.ttf(data);
    return _regularFont!;
  }

  /// Loads and caches the bold Arabic/English font
  static Future<pw.Font> getBoldFont() async {
    if (_boldFont != null) return _boldFont!;
    final data = await rootBundle.load('assets/fonts/DGAgnadeen-Bold.ttf');
    _boldFont = pw.Font.ttf(data);
    return _boldFont!;
  }

  /// Loads the active project custom logo (if set) or falls back to Tahsel app logo
  static Future<pw.MemoryImage?> getLogoImage() async {
    try {
      final customBytes = await ProjectLogoService.instance.getLogoBytes();
      if (customBytes != null && customBytes.isNotEmpty) {
        return pw.MemoryImage(customBytes);
      }

      if (_logoImage != null) return _logoImage;
      if (_logoBytes == null) {
        final data = await rootBundle.load(Assets.imagesAppLogo);
        _logoBytes = data.buffer.asUint8List();
      }
      if (_logoBytes != null) {
        _logoImage = pw.MemoryImage(_logoBytes!);
      }
    } catch (_) {}
    return _logoImage;
  }
}
