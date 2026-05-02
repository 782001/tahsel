import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/extensions/string_extensions.dart';
import '../../core/utils/app_strings.dart';

class SmsService {
  /// Prepares the message in a background isolate for performance.
  static Future<String> prepareMessage({
    required String name,
    required double amount,
    required double remaining,
    required String date,
    required String note,
    String? template,
  }) async {
    return await compute(_buildMessage, {
      'name': name,
      'amount': amount,
      'remaining': remaining,
      'date': date,
      'note': note,
      'template': template ?? AppStrings.smsMsgTemplate.tr(),
    });
  }

  static String _buildMessage(Map<String, dynamic> data) {
    final name = data['name'] as String;
    final amount = data['amount'] as double;
    final remaining = data['remaining'] as double;
    final date = data['date'] as String;
    final note = data['note'] as String;
    final template = data['template'] as String;

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

  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Basic normalization
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('SMS Launch Error: $e');
      return false;
    }
  }
}
