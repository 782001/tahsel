class SearchKeywordsBuilder {
  SearchKeywordsBuilder._();

  static List<String> build({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
  }) {
    final keywords = <String>{};
    if (uid != null && uid.isNotEmpty) keywords.add(uid.toLowerCase());
    if (email != null && email.isNotEmpty) keywords.add(email.toLowerCase());
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      keywords.add(phoneNumber.replaceAll(' ', ''));
    }
    if (fullName != null && fullName.isNotEmpty) {
      keywords.add(fullName.toLowerCase());
      for (final part in fullName.split(' ')) {
        final trimmed = part.trim().toLowerCase();
        if (trimmed.isNotEmpty) keywords.add(trimmed);
      }
    }
    return keywords.toList();
  }
}
