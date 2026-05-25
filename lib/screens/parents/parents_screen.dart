// lib/parents/parents_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_parent_screen.dart';
import 'parent_pin_gate_screen.dart';

class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF7ED),
          appBar: AppBar(
            backgroundColor: const Color(0xFFEEA66A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Parents',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: snapshot.hasData ? const ParentPinGateScreen() : const AuthParentScreen(),
        );
      },
    );
  }
}
