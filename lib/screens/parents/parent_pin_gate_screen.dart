import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import 'set_parent_pin_screen.dart';
import 'parent_dashboard_screen.dart';

class ParentPinGateScreen extends StatefulWidget {
  final Widget? onSuccessGoTo;
  const ParentPinGateScreen({super.key, this.onSuccessGoTo});

  @override
  State<ParentPinGateScreen> createState() => _ParentPinGateScreenState();
}

class _ParentPinGateScreenState extends State<ParentPinGateScreen> {
  bool _loading = true;
  String? _storedPin;
  String _entered = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = "Please sign in from the Parent area first.";
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
      final pin = doc.data()?['pin'] as String?;

      if (!mounted) return;

      setState(() {
        _storedPin = pin;
        _loading = false;
      });

      if (pin == null || pin.trim().isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetParentPinScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Connection error. Check your internet.";
      });
    }
  }

  Future<void> _verify() async {
    setState(() => _error = null);

    if (_entered.length != 4) {
      setState(() => _error = 'Enter 4 digits');
      return;
    }

    if (_storedPin == null) {
      setState(() => _error = 'PIN not set yet');
      return;
    }

    if (_entered != _storedPin) {
      setState(() {
        _error = 'Wrong PIN 🙂 Try again.';
        _entered = '';
      });
      return;
    }

    if (!mounted) return;
    final next = widget.onSuccessGoTo ?? const ParentDashboardScreen();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  void _pressDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() => _entered += d);
    if (_entered.length == 4) _verify();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: const Text('Parent PIN', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_error != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(22)),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.textDark),
                    SizedBox(width: 10),
                    Expanded(child: Text('Enter your PIN to open Parent Space.', style: TextStyle(color: AppColors.textDark, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: i < _entered.length ? AppColors.textDark : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textDark.withOpacity(0.2)),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _PinPad(onDigit: _pressDigit, onBackspace: _backspace),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetParentPinScreen())),
                child: const Text('Change PIN', style: TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  const _PinPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
        const SizedBox.shrink(),
        _buildKey('0'),
        _buildKey('⌫', isBackspace: true),
      ],
    );
  }

  Widget _buildKey(String text, {bool isBackspace = false}) {
    return InkWell(
      onTap: isBackspace ? onBackspace : () => onDigit(text),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardBlue, borderRadius: BorderRadius.circular(18)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark))),
      ),
    );
  }
}