import 'package:flutter/material.dart';

class DeviderWidget extends StatelessWidget {
  const DeviderWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: .5,
            strokeAlign: BorderSide.strokeAlignCenter,
            color: const Color(0x194A4E9C),
          ),
        ),
      ),
    );
  }
}
