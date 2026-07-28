import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  static Future<String?> scan(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const BarcodeScannerDialog(),
    );
  }

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  late MobileScannerController _scannerController;
  final TextEditingController _manualBarcodeController =
      TextEditingController();
  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _isScanned = true;
        Navigator.of(context).pop(barcode.rawValue);
        break;
      }
    }
  }

  void _submitManualBarcode() {
    final code = _manualBarcodeController.text.trim();
    if (code.isNotEmpty) {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(isDesktop ? 32 : 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20.r),
      ),
      child: Container(
        width: isDesktop ? 450 : 340.w,
        height: isDesktop ? 550 : 500.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 20.r),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 14.w,
                vertical: isDesktop ? 12 : 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryColor,
                    size: isDesktop ? 22 : 20.r,
                  ),
                  SizedBox(width: isDesktop ? 10 : 8.w),
                  Expanded(
                    child: Text(
                      'مسح الباركود 📷',
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Camera View & Scanner Overlay
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: AppColors.subTitleColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'تعذر تشغيل الكاميرا أو لا توجد كاميرا متصلة',
                                textAlign: TextAlign.center,
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  color: AppColors.subTitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Scanner Frame Overlay
                  Center(
                    child: Container(
                      width: isDesktop ? 260 : 230.w,
                      height: isDesktop ? 180 : 160.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.vipGoldStart,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.vipGoldStart.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Controls Overlay (Torch & Camera Switch)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Icon(
                              _isTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _isTorchOn
                                  ? AppColors.vipGoldStart
                                  : Colors.white,
                            ),
                            onPressed: () async {
                              await _scannerController.toggleTorch();
                              setState(() {
                                _isTorchOn = !_isTorchOn;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => _scannerController.switchCamera(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Manual Fallback Input Area (Crucial for Desktop/USB Scanner)
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'وجّه الكاميرا نحو الباركود أو أدخله يدوياً ⌨️',
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: AppColors.subTitleColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: QuickAddTextField(
                          controller: _manualBarcodeController,
                          hint: AppStrings.barcode.tr(),
                          icon: Icons.qr_code_rounded,
                          onSubmitted: (_) => _submitManualBarcode(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _submitManualBarcode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 14 : 12.w,
                            vertical: isDesktop ? 12 : 10.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          AppStrings.confirm.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
