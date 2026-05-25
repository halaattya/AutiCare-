import 'package:flutter/material.dart';
import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';

class DailyLogInfoScreen extends StatelessWidget {
  const DailyLogInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: Text(
          t.t('daily_log_info_title'),
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: t.t('dli_what_log_does'),
            bullets: [
              t.t('dli_b1'),
              t.t('dli_b2'),
              t.t('dli_b3'),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: t.t('dli_how_to_use'),
            bullets: [
              t.t('dli_b4'),
              t.t('dli_b5'),
              t.t('dli_b6'),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: t.t('dli_why_doctors'),
            bullets: [
              t.t('dli_b7'),
              t.t('dli_b8'),
              t.t('dli_b9'),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: t.t('dli_privacy'),
            bullets: [
              t.t('dli_b10'),
              t.t('dli_b11'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<String> bullets;

  const _Card({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
                    Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
