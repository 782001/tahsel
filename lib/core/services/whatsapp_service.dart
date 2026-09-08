import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_share2/whatsapp_share2.dart';

import 'receipt_image_service.dart';

class WhatsAppService {
  /// Launches WhatsApp with a specific phone number and message
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // Format phone number: remove non-digits and ensure it starts with country code
    // For Egypt (EGP currency used in app), default to +20 if no country code
    String formattedPhone = phoneNumber.toWhatsAppFormat();

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      return false;
    }
  }

  /// Prepares the message content using an isolate
  static Future<String> prepareMessage({
    required String name,
    required double amount,
    required double remaining,
    required String date,
    String? note,
    String? template,
  }) async {
    return await compute(_buildMessage, {
      'name': name,
      'amount': amount,
      'remaining': remaining,
      'date': date,
      'note': note ?? '',
      'template': template ?? AppStrings.whatsappMsgTemplate.tr(),
    });
  }

  static String _buildMessage(Map<String, dynamic> params) {
    final String name = params['name'] as String;
    final double amount = params['amount'] as double;
    final double remaining = params['remaining'] as double;
    final String date = params['date'] as String;
    final String note = params['note'] as String;
    final String template = params['template'] as String;

    String message = template;

    // If note is empty, remove the entire line containing {note}
    if (note.trim().isEmpty) {
      final lines = message.split('\n');
      message = lines.where((line) => !line.contains('{note}')).join('\n');
    }

    message = message
        .replaceAll('{name}', name)
        .replaceAll('{amount}', amount.toStringAsFixed(2))
        .replaceAll('{remaining}', remaining.toStringAsFixed(2))
        .replaceAll('{date}', date)
        .replaceAll('{note}', note);

    return message;
  }

  static Future<bool> sendReceipt({
    required String phoneNumber,
    required String message,
    required String customerName,
    required double paid,
    required double total,
    required double remaining,
    bool isCustomerReceipt = true,
  }) async {
    final image = await ReceiptImageService.generateReceipt(
      customerName: customerName,
      paid: paid,
      total: total,
      remaining: remaining,
      isArabic: AppStrings.currentLang == "ar" ? true : false,
      isCustomerReceipt: isCustomerReceipt,
    );
    AppLogger.printMessage(image.path);
    AppLogger.printMessage(await image.exists() ? "exists" : "not exists");
    AppLogger.printMessage("${await image.length()}");

    // On Windows desktop, share_plus does not support file sharing (dev.fluttercommunity.plus/share channel).
    // Instead, open the generated receipt image and launch WhatsApp with the prefilled message.
    if (!kIsWeb && Platform.isWindows) {
      try {
        await Process.run('cmd', ['/c', 'start', '', image.path]);
      } catch (_) {
        try {
          await Process.run('explorer.exe', ['/select,', image.path]);
        } catch (_) {}
      }
      return await sendMessage(
        phoneNumber: phoneNumber,
        message: message,
      );
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        String formattedPhone = phoneNumber.toWhatsAppFormat();

        final success = await WhatsappShare.shareFile(
          phone: formattedPhone,
          filePath: [image.path],
          text: message,
        );
        if (success == true) {
          return true;
        }
      } catch (e) {
        AppLogger.printMessage("WhatsappShare error: $e");
      }
    }

    // Fallback using Share.shareXFiles
    try {
      await Share.shareXFiles(
        [XFile(image.path)],
        text: message,
        subject: 'Receipt',
      );
      return true;
    } catch (e) {
      AppLogger.printMessage("Share.shareXFiles fallback error: $e");
      return await sendMessage(
        phoneNumber: phoneNumber,
        message: message,
      );
    }
  }
}
