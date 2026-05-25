import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';

import 'parent_dashboard_screen.dart';

class SetParentPinScreen extends StatefulWidget {
  const SetParentPinScreen({super.key});

  @override
  State<SetParentPinScreen> createState() => _SetParentPinScreenState();
}

class _SetParentPinScreenState extends State<SetParentPinScreen> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _savePin() async {
    final t = AppLocalizations.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    final p1 = _pin1.text.trim();
    final p2 = _pin2.text.trim();

    if (p1.length != 4 || p2.length != 4) {
      setState(() {
        _saving = false;
        _error = t.t('err_pin_4_digits');
      });
      return;
    }
    if (p1 != p2) {
      setState(() {
        _saving = false;
        _error = t.t('err_pins_not_match');
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _saving = false;
        _error = t.t('err_not_logged_in');
      });
      return;
    }

    await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
      'pin': p1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
    );
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
        backgroundColor: AppColors.cardLavender,
        elevation: 0,
        title: Text(
          t.t('set_parent_pin_title'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Padding(
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
                    const Icon(Icons.shield, color: AppColors.textDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.t('set_pin_info'),
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _pin1,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: _dec(t.t('field_enter_pin')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pin2,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: _dec(t.t('field_confirm_pin')),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 2,
                  ),
                  onPressed: _saving ? null : _savePin,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          t.t('btn_save_pin'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
