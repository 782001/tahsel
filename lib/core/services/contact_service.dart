import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';

class ContactService {
  static Future<Map<String, String>?> pickContact(BuildContext context) async {
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            String? phone;
            if (fullContact.phones.isEmpty) {
              return {'name': fullContact.displayName, 'phone': ''};
            } else if (fullContact.phones.length == 1) {
              phone = fullContact.phones.first.number;
            } else {
              // Let user select one if multiple numbers
              phone = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppStrings.selectFromContacts.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: fullContact.phones
                        .map(
                          (p) => ListTile(
                            title: Text(p.number),
                            onTap: () => Navigator.pop(ctx, p.number),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            }

            if (phone != null) {
              return {
                'name': fullContact.displayName,
                'phone': phone.replaceAll(RegExp(r'\s+'), ''),
              };
            }
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.permissionDenied.tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    return null;
  }
}
