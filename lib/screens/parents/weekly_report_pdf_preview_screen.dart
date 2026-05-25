import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';

class WeeklyReportPdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() buildPdfBytes;

  const WeeklyReportPdfPreviewScreen({
    super.key,
    required this.buildPdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('pdf_weekly_report_title')),
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
      ),
    );
  }
}
