import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  bool _isArabic = true;
  void submitLang(BuildContext context, String lang) {
    if (lang == 'ar') {
      BlocProvider.of<LocaleCubit>(context).toArabic();
    } else {
      BlocProvider.of<LocaleCubit>(context).toEnglish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.language,
                  color: Color(0xFF00AD98),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              TextWidget(
                'اللغة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// Language Toggle
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // Arabic Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isArabic = true;
                      });
                      submitLang(context, 'ar');
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: _isArabic
                            ? const LinearGradient(
                                colors: [Color(0xFF014d4d), Color(0xFF00897B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: _isArabic
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: TextWidget(
                        'العربية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _isArabic
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _isArabic ? Colors.white : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // English Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isArabic = false;
                      });
                      submitLang(context, 'en');
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isArabic ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: !_isArabic
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: TextWidget(
                        'English',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: !_isArabic
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: !_isArabic
                              ? const Color(0xFF004D40)
                              : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
