import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';

class WhatsAppService {
  /// Launches WhatsApp with a specific phone number and message
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // Format phone number: remove non-digits and ensure it starts with country code
    // For Egypt (EGP currency used in app), default to +20 if no country code
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!formattedPhone.startsWith('20') && !formattedPhone.startsWith('+')) {
      formattedPhone = '20$formattedPhone';
    }

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      return await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
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

    String message = template
        .replaceAll('{name}', name)
        .replaceAll('{amount}', amount.toStringAsFixed(2))
        .replaceAll('{remaining}', remaining.toStringAsFixed(2))
        .replaceAll('{date}', date)
        .replaceAll('{note}', note);

    return message;
  }
}
