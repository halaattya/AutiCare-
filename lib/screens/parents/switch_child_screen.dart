import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';

class SwitchChildScreen extends StatelessWidget {
  const SwitchChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not signed in")));
    }

    final parentRef =
        FirebaseFirestore.instance.collection('parents').doc(user.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: const Text(
          'Switch Child',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('linkedAdults', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No children linked to this parent.",
                style: TextStyle(color: AppColors.textSoft),
              ),
            );
          }

          // sort locally by createdAt if exists
          docs.sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            final aM = (aTs is Timestamp) ? aTs.millisecondsSinceEpoch : 0;
            final bM = (bTs is Timestamp) ? bTs.millisecondsSinceEpoch : 0;
            return aM.compareTo(bM);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final name = (data['name'] ?? 'Child').toString();
              final username = (data['username'] ?? '').toString();

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.cardLavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.child_care, color: AppColors.textDark),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: username.isEmpty
                      ? null
                      : Text(
                          '@$username',
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textDark),
                  onTap: () async {
                    await parentRef.set(
                      {
                        'activeChildId': d.id,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to $name ✅')),
                      );
                      Navigator.pop(context, true);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
