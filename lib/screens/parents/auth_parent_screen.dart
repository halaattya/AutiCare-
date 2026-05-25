import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'parent_pin_gate_screen.dart';

class AuthParentScreen extends StatefulWidget {
  const AuthParentScreen({super.key});

  @override
  State<AuthParentScreen> createState() => _AuthParentScreenState();
}

class _AuthParentScreenState extends State<AuthParentScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _isLogin = true;
  String? _error;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);

    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.length < 6) {
      setState(() => _error = t.t('err_email_pass_invalid'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentPinGateScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? t.t('err_auth_failed'));
    } catch (_) {
      setState(() => _error = t.t('err_auth_failed'));
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                _isLogin ? t.t('parent_login_title') : t.t('parent_signup_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 18),

              TextField(controller: _email, decoration: _dec(t.t('field_email'))),
              const SizedBox(height: 10),
              TextField(
                controller: _pass,
                decoration: _dec(t.t('field_password')),
                obscureText: true,
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
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLogin ? t.t('btn_login') : t.t('btn_signup'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: _loading ? null : () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? t.t('toggle_create_account') : t.t('toggle_have_account'),
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w700,
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
