import 'package:cloud_firestore/cloud_firestore.dart';
import 'active_child_provider.dart';
import 'daily_log_model.dart';
import '../../l10n/app_localizations.dart';
class DailyLogService {
  static String dateIdFrom(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Future<String?> _childId() => ActiveChildProvider.getActiveChildId();

  static Future<DailyLog?> getLogForDate(DateTime date) async {
    final childId = await _childId();
    if (childId == null) return null;

    final id = dateIdFrom(date);
    final doc = await FirebaseFirestore.instance
        .collection('children')
        .doc(childId)
        .collection('daily_logs')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return DailyLog.fromMap(doc.data()!);
  }

  static Future<void> saveLog(DailyLog log) async {
    final childId = await _childId();
    if (childId == null) return;

    await FirebaseFirestore.instance
        .collection('children')
        .doc(childId)
        .collection('daily_logs')
        .doc(log.dateId)
        .set(log.toMap(), SetOptions(merge: true));
  }
}
