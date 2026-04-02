import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class FullImageDialog extends StatelessWidget {
  final String imageUrl;

  const FullImageDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
      child: SizedBox(
        height: 0.5.sh,
        width: 0.9.sw,
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: ErrorPlaceholder(
                  width: 0.9.sw,
                  height: 0.5.sh,
                  message: 'Failed to load image',
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ErrorPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final String message;

  const ErrorPlaceholder({
    required this.width,
    required this.height,
    this.message = 'No Image Available',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[400], size: 40.sp),
            SizedBox(height: 10.h),
            TextWidget(
              message,
              style: TextStyles.font16Weight400Text().copyWith(
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
