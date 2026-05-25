import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';

class LinkChildScreen extends StatefulWidget {
  const LinkChildScreen({super.key});

  @override
  State<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final _username = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _link() async {
    final t = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final input = _username.text.trim();
    if (input.isEmpty || !input.contains('_')) {
      setState(() => _error = t.t('err_enter_valid_username'));
      return;
    }

    final key = input.toLowerCase();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final q = await FirebaseFirestore.instance
          .collection('children')
          .where('usernameKey', isEqualTo: key)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        setState(() {
          _loading = false;
          _error = t.t('err_username_not_found');
        });
        return;
      }

      final childDoc = q.docs.first;

      await FirebaseFirestore.instance.collection('children').doc(childDoc.id).set({
        'linkedAdults': FieldValue.arrayUnion([user.uid]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
        'activeChildId': childDoc.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = t.t('err_failed_link_child'));
    }

    if (mounted) setState(() => _loading = false);
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.textSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBlue,
        elevation: 0,
        title: Text(
          t.t('link_child_title'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.textDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.t('link_child_info'),
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _username,
              textCapitalization: TextCapitalization.none,
              decoration: _dec(t.t('field_child_username_example')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: _loading ? null : _link,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        t.t('btn_link'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
