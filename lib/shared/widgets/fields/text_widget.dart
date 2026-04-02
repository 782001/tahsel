import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  const TextWidget(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  final String? text;

  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return TextWidget(
      text ?? '',
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines == 1 ? TextOverflow.ellipsis : null),
    );
  }
}
