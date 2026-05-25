import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';

class DailyLogPdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() buildPdfBytes;

  /// Optional localization key for the title.
  /// If null -> uses 'pdf_daily_log_title'
  final String? titleKey;

  const DailyLogPdfPreviewScreen({
    super.key,
    required this.buildPdfBytes,
    this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isAr = t.locale.languageCode == 'ar';

    final resolvedTitle = t.t(titleKey ?? 'pdf_daily_log_title');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(resolvedTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: t.t('back'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: PdfPreview(
          build: (_) => buildPdfBytes(),
          allowPrinting: true,
          allowSharing: true,
          canChangeOrientation: false,
          // optional but nice:
          canChangePageFormat: false,
        ),
      ),
    );
  }
}
