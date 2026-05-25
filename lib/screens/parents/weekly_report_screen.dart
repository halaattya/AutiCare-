import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../tracking/active_child_provider.dart';
import '../../tracking/game_definitions.dart';
import '../../tracking/game_ids.dart';
import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'weekly_report_pdf_preview_screen.dart';

/// ✅ Display title override for some games (UI + PDF)
String _weeklyDisplayTitle(String gameId) {
  if (gameId == GameIds.communication) return 'Match Face Expression';
  return GameDefinitions.forId(gameId).title;
}

/// ✅ Card color by category (Cognitive / Attention / Communication)
Color _weeklyCardColorForGame(String gameId) {
  // Soft pastel colors (kept local so we don't need to modify AppColors)
  const cognitive = Color(0xFFE9D9FF); // lilac
  const attention = Color(0xFFD9F2E6); // mint
  const communication = Color(0xFFFFE7D6); // peach

  if (gameId == GameIds.tapTarget) return attention;
  if (gameId == GameIds.communication) return communication;

  // Memory + Shape Matching = cognitive by default
  return cognitive;
}

/// ✅ FIX: Safe metric reading + fallbacks for old Communication sessions
num? _readMetric(Map<String, dynamic> metrics, String key, String gameId) {
  final v = metrics[key];
  if (v is num) return v;

  if (gameId == GameIds.communication) {
    // old sessions stored score instead of successfulResponses
    if (key == 'successfulResponses') {
      final score = metrics['score'];
      if (score is num) return score;
    }
    // old sessions never had promptLevel
    if (key == 'promptLevel') return 0;
  }

  return null;
}

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final now = DateTime.now();
    final start7 = now.subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: Text(
          t.t('weekly_report'),
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          // ✅ PDF export button
          IconButton(
            tooltip: t.t('export_pdf'), // add to localization if missing
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              // We need the same data that is shown on screen.
              final childId = await ActiveChildProvider.getActiveChildId();
              if (childId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('no_active_child_selected'))),
                );
                return;
              }

              final q = FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .collection('game_sessions')
                  .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start7))
                  .orderBy('startedAt', descending: false);

              final snap = await q.get();
              final docs = snap.docs;

              if (docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('no_sessions_last_7'))),
                );
                return;
              }

              final allSessions = docs.map((e) => e.data()).toList();

              // Group by gameId
              final Map<String, List<Map<String, dynamic>>> byGame = {};
              for (final d in allSessions) {
                final gameId = (d['gameId'] ?? '').toString();
                if (gameId.isEmpty) continue;
                (byGame[gameId] ??= []).add(d);
              }

              // Child info for header (optional)
              final childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
              final childName = (childDoc.data()?['name'] ?? '').toString();

              final pdf = await _buildWeeklyPdf(
                t: t,
                childName: childName.isEmpty ? t.t('dash') : childName,
                start: start7,
                end: now,
                allSessions: allSessions,
                byGame: byGame,
              );

              final pdfBytes = await pdf.save();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeeklyReportPdfPreviewScreen(
                    buildPdfBytes: () async => pdfBytes,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: ActiveChildProvider.getActiveChildId(),
        builder: (context, childSnap) {
          if (!childSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final childId = childSnap.data;
          if (childId == null) {
            return Center(child: Text(t.t('no_active_child_selected')));
          }

          final q = FirebaseFirestore.instance
              .collection('children')
              .doc(childId)
              .collection('game_sessions')
              .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start7))
              .orderBy('startedAt', descending: false);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: q.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(child: Text(t.t('no_sessions_last_7')));
              }

              final allSessions = docs.map((e) => e.data()).toList();

              // Group by gameId
              final Map<String, List<Map<String, dynamic>>> byGame = {};
              for (final d in allSessions) {
                final gameId = (d['gameId'] ?? '').toString();
                if (gameId.isEmpty) continue;
                (byGame[gameId] ??= []).add(d);
              }

              return ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _BigSummaryHeader(allSessions: allSessions),
                  const SizedBox(height: 14),
                  ...byGame.entries.map((entry) {
                    final gameId = entry.key;
                    final def = GameDefinitions.forId(gameId);
                    final sessions = entry.value;

                    final completed = sessions.where((s) => s['completed'] == true).length;
                    final dropped = sessions.length - completed;

                    int totalSec = 0;
                    final primary = <double>[];
                    final secondary = <double>[];

                    // 7-day trend points: avg primary per day
                    final List<double> trendSum = List.filled(7, 0);
                    final List<int> trendCount = List.filled(7, 0);

                    for (final s in sessions) {
                      final dur = s['durationSec'];
                      if (dur is num) totalSec += dur.toInt();

                      final metrics = (s['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

                      final pNum = _readMetric(metrics, def.primaryMetricKey, gameId);
                      if (pNum is num) primary.add(pNum.toDouble());

                      if (def.secondaryMetricKey != null) {
                        final secNum = _readMetric(metrics, def.secondaryMetricKey!, gameId);
                        if (secNum is num) secondary.add(secNum.toDouble());
                      }

                      final ts = s['startedAt'] as Timestamp?;
                      final dt = ts?.toDate();
                      if (dt != null && pNum is num) {
                        final diff = dt.difference(start7).inDays;
                        if (diff >= 0 && diff < 7) {
                          trendSum[diff] += pNum.toDouble();
                          trendCount[diff] += 1;
                        }
                      }
                    }

                    final trend = List<double>.generate(7, (i) {
                      if (trendCount[i] == 0) return 0;
                      return trendSum[i] / trendCount[i];
                    });

                    final primaryAvg =
                        primary.isEmpty ? null : primary.reduce((a, b) => a + b) / primary.length;
                    final secondaryAvg =
                    secondary.isEmpty ? null : secondary.reduce((a, b) => a + b) / secondary.length;

                    final completionRate = sessions.isEmpty ? 0.0 : (completed / sessions.length);

                    return _GameReportCard(
                      title: _weeklyDisplayTitle(gameId),
                      cardColor: _weeklyCardColorForGame(gameId),
                      gameId: gameId,
                      plays: sessions.length,
                      dropped: dropped,
                      totalSec: totalSec,
                      completionRate: completionRate,
                      primaryLabel: def.primaryMetricKey,
                      primaryAvg: primaryAvg,
                      secondaryLabel: def.secondaryMetricKey,
                      secondaryAvg: secondaryAvg,
                      secondaryLowerIsBetter: def.secondaryMetricKey != null && def.secondaryHigherIsBetter == false,
                      trend: trend,
                      sessions: sessions,
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- PDF (professional layout) ----------------

Future<pw.Document> _buildWeeklyPdf({
  required AppLocalizations t,
  required String childName,
  required DateTime start,
  required DateTime end,
  required List<Map<String, dynamic>> allSessions,
  required Map<String, List<Map<String, dynamic>>> byGame,
}) async {
  final pdf = pw.Document();

  String fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String minFromSec(int sec) => '${(sec / 60).floor()} min';

  // Summary
  int totalSec = 0;
  final Map<String, int> timePerGame = {};
  final Map<String, int> dropsPerGame = {};
  final Map<String, int> playsPerGame = {};

  for (final s in allSessions) {
    final gid = (s['gameId'] ?? '').toString();
    final dur = s['durationSec'];
    final completed = s['completed'] == true;

    if (dur is num) {
      totalSec += dur.toInt();
      timePerGame[gid] = (timePerGame[gid] ?? 0) + dur.toInt();
    }
    playsPerGame[gid] = (playsPerGame[gid] ?? 0) + 1;
    if (!completed) dropsPerGame[gid] = (dropsPerGame[gid] ?? 0) + 1;
  }

  String favorite = t.t('dash');
  int bestTime = -1;
  timePerGame.forEach((gid, sec) {
    if (sec > bestTime) {
      bestTime = sec;
      favorite = _weeklyDisplayTitle(gid);
    }
  });

  String mostDropped = t.t('dash');
  double worstRate = -1;
  dropsPerGame.forEach((gid, drops) {
    final plays = playsPerGame[gid] ?? 1;
    if (plays < 2) return;
    final rate = drops / plays;
    if (rate > worstRate) {
      worstRate = rate;
      mostDropped = _weeklyDisplayTitle(gid);
    }
  });

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return [
          pw.Text(
            'Weekly Progress Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Child: $childName'),
          pw.Text('Period: ${fmtDate(start)} - ${fmtDate(end)}'),
          pw.SizedBox(height: 16),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Total Play Time: ${minFromSec(totalSec)}'),
                pw.Text('Favorite Game: $favorite'),
                pw.Text('Most Dropped Game: $mostDropped'),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Game Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),

          ...byGame.entries.map((entry) {
            final gameId = entry.key;
            final def = GameDefinitions.forId(gameId);
            final sessions = entry.value;

            final completed = sessions.where((s) => s['completed'] == true).length;
            final dropped = sessions.length - completed;

            int gSec = 0;
            final primary = <double>[];
            final secondary = <double>[];

            for (final s in sessions) {
              final dur = s['durationSec'];
              if (dur is num) gSec += dur.toInt();

              final metrics = (s['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

              final pNum = _readMetric(metrics, def.primaryMetricKey, gameId);
              if (pNum is num) primary.add(pNum.toDouble());

              if (def.secondaryMetricKey != null) {
                final secNum = _readMetric(metrics, def.secondaryMetricKey!, gameId);
                if (secNum is num) secondary.add(secNum.toDouble());
              }
            }

            final primaryAvg = primary.isEmpty ? null : primary.reduce((a, b) => a + b) / primary.length;
            final secondaryAvg =
            secondary.isEmpty ? null : secondary.reduce((a, b) => a + b) / secondary.length;
            final completionRate = sessions.isEmpty ? 0.0 : (completed / sessions.length);

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(_weeklyDisplayTitle(gameId),
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    children: [
                      _pdfRow('Plays', '${sessions.length}'),
                      _pdfRow('Dropped', '$dropped'),
                      _pdfRow('Time', minFromSec(gSec)),
                      _pdfRow('Completion', '${(completionRate * 100).toStringAsFixed(0)}%'),
                      _pdfRow('Avg ${def.primaryMetricKey}',
                          primaryAvg == null ? '-' : primaryAvg.toStringAsFixed(2)),
                      if (def.secondaryMetricKey != null)
                        _pdfRow('Avg ${def.secondaryMetricKey!}',
                            secondaryAvg == null ? '-' : secondaryAvg.toStringAsFixed(2)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ];
      },
    ),
  );

  return pdf;
}

pw.TableRow _pdfRow(String a, String b) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(a, style: const pw.TextStyle(fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(b, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ),
    ],
  );
}

// ---------------- UI widgets below (unchanged) ----------------

class _BigSummaryHeader extends StatelessWidget {
  final List<Map<String, dynamic>> allSessions;
  const _BigSummaryHeader({required this.allSessions});

  String _min(int sec) => '${(sec / 60).floor()} min';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    int totalSec = 0;
    final Map<String, int> timePerGame = {};
    final Map<String, int> dropsPerGame = {};
    final Map<String, int> playsPerGame = {};

    for (final s in allSessions) {
      final gid = (s['gameId'] ?? '').toString();
      final dur = s['durationSec'];
      final completed = s['completed'] == true;

      if (dur is num) {
        totalSec += dur.toInt();
        timePerGame[gid] = (timePerGame[gid] ?? 0) + dur.toInt();
      }
      playsPerGame[gid] = (playsPerGame[gid] ?? 0) + 1;
      if (!completed) dropsPerGame[gid] = (dropsPerGame[gid] ?? 0) + 1;
    }

    String favorite = t.t('dash');
    int bestTime = -1;
    timePerGame.forEach((gid, sec) {
      if (sec > bestTime) {
        bestTime = sec;
        favorite = _weeklyDisplayTitle(gid);
      }
    });

    String mostDropped = t.t('dash');
    double worstRate = -1;
    dropsPerGame.forEach((gid, drops) {
      final plays = playsPerGame[gid] ?? 1;
      if (plays < 2) return;
      final rate = drops / plays;
      if (rate > worstRate) {
        worstRate = rate;
        mostDropped = _weeklyDisplayTitle(gid);
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardPeach,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.t('weekly_summary'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(t.t('total_play'), _min(totalSec)),
              _pill(t.t('favorite'), favorite),
              _pill(t.t('most_dropped'), mostDropped),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.t('tap_game_card_expand'),
            style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _pill(String a, String b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Text('$a: $b', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
    );
  }
}

class _GameReportCard extends StatefulWidget {
  final String title;
  final String gameId;
  final Color cardColor;
  final int plays;
  final int dropped;
  final int totalSec;
  final double completionRate;

  final String primaryLabel;
  final double? primaryAvg;

  final String? secondaryLabel;
  final double? secondaryAvg;
  final bool secondaryLowerIsBetter;

  final List<double> trend;
  final List<Map<String, dynamic>> sessions;

  const _GameReportCard({
    required this.title,
    required this.gameId,
    required this.cardColor,
    required this.plays,
    required this.dropped,
    required this.totalSec,
    required this.completionRate,
    required this.primaryLabel,
    required this.primaryAvg,
    required this.secondaryLabel,
    required this.secondaryAvg,
    required this.secondaryLowerIsBetter,
    required this.trend,
    required this.sessions,
  });

  @override
  State<_GameReportCard> createState() => _GameReportCardState();
}

class _GameReportCardState extends State<_GameReportCard> {
  bool open = false;

  String _min(int sec) => '${(sec / 60).floor()} min';
  String _pct(double x) => '${(x * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => open = !open),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.textDark),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill(t.t('plays'), '${widget.plays}'),
                _pill(t.t('dropped'), '${widget.dropped}'),
                _pill(t.t('time'), _min(widget.totalSec)),
                _pill(t.t('completion'), _pct(widget.completionRate)),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(height: 70, width: double.infinity, child: _Sparkline(values: widget.trend)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('${t.t('avg')} ${widget.primaryLabel}',
                    widget.primaryAvg == null ? t.t('dash') : widget.primaryAvg!.toStringAsFixed(2)),
                if (widget.secondaryLabel != null)
                  _pill(
                    '${t.t('avg')} ${widget.secondaryLabel}',
                    widget.secondaryAvg == null
                        ? t.t('dash')
                        : widget.secondaryLowerIsBetter
                            ? '${widget.secondaryAvg!.toStringAsFixed(0)} (${t.t('lower_better')})'
                            : widget.secondaryAvg!.toStringAsFixed(2),
                  ),
              ],
            ),

            if (open) ...[
              const SizedBox(height: 14),
              Text(
                t.t('latest_sessions_proof'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),

              ...widget.sessions.reversed.take(12).map((s) {
                final completed = s['completed'] == true;
                final dur = (s['durationSec'] is num) ? (s['durationSec'] as num).toInt() : 0;
                final metrics = (s['metrics'] as Map?)?.cast<String, dynamic>() ?? {};
                final def = GameDefinitions.forId(widget.gameId);
                final pNum = _readMetric(metrics, def.primaryMetricKey, widget.gameId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(completed ? Icons.check_circle : Icons.cancel, color: AppColors.textDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${t.t('duration')}: ${dur}s  •  ${t.t('primary')}: ${pNum ?? t.t('dash')}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String a, String b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Text('$a: $b', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklinePainter(values));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> v;
  _SparklinePainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final dot = Paint()..style = PaintingStyle.fill;

    final minV = v.reduce((a, b) => a < b ? a : b);
    final maxV = v.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    Offset pt(int i) {
      final x = (size.width / (v.length - 1)) * i;
      final norm = (v[i] - minV) / range;
      final y = size.height - (norm * (size.height - 10)) - 5;
      return Offset(x, y);
    }

    final path = Path();
    for (int i = 0; i < v.length; i++) {
      final p = pt(i);
      if (i == 0) path.moveTo(p.dx, p.dy);
      else path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, line);
    for (int i = 0; i < v.length; i++) {
      final p = pt(i);
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.v != v;
}
