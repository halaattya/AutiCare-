import 'package:cloud_firestore/cloud_firestore.dart';
import 'active_child_provider.dart';

class ParentControlsService {
  static Future<String?> _childId() => ActiveChildProvider.getActiveChildId();

  static Future<bool> getKeepRandomPlay() async {
    final childId = await _childId();
    if (childId == null) return false;

    final doc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
    final data = doc.data();
    final pc = (data?['parentControls'] as Map?)?.cast<String, dynamic>() ?? {};
    return pc['keepRandomPlay'] == true;
  }

  static Future<void> setKeepRandomPlay(bool value) async {
    final childId = await _childId();
    if (childId == null) return;

    await FirebaseFirestore.instance.collection('children').doc(childId).set({
      'parentControls': {
        'keepRandomPlay': value,
      }
    }, SetOptions(merge: true));
  }
}
