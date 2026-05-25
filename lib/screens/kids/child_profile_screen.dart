import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ChildProfileScreen extends StatelessWidget {
  const ChildProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardLavender,
          elevation: 0,
          title: Text(t.t('child_profile_title')),
        ),
        body: Center(child: Text(t.t('ask_parent_signin'))),
      );
    }

    final parentDoc = FirebaseFirestore.instance.collection('parents').doc(user.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardLavender,
        elevation: 0,
        // Using centerTitle ensures it matches the design even if title length varies
        centerTitle: true,
        title: Text(
          t.t('child_profile_title'),
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: parentDoc.snapshots(),
        builder: (context, parentSnap) {
          if (parentSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final parentData = parentSnap.data?.data() as Map<String, dynamic>? ?? {};
          final activeChildId = parentData['activeChildId'] as String?;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                // Header Info Message
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.textDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.t('profile_info_msg'),
                          style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: (activeChildId == null || activeChildId.isEmpty)
                      ? Center(child: Text(t.t('no_active_child')))
                      : StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('children')
                              .doc(activeChildId)
                              .snapshots(),
                          builder: (context, childSnap) {
                            if (childSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final childData = childSnap.data?.data() as Map<String, dynamic>?;

                            if (childData == null) {
                              return Center(child: Text(t.t('no_active_child')));
                            }

                            // --- FIXED DATA MAPPING ---
                            final name = (childData['name'] ?? 'Child').toString();
                            final username = (childData['username'] ?? '').toString();
                            
                            // 1. Correct Goal Area mapping (Look for mainGoalAreaKey)
                            final goalKey = (childData['mainGoalAreaKey'] ?? '').toString();
                            final goalValue = goalKey.isEmpty ? t.t('not_set') : t.t(goalKey);

                            // 2. Correct Communication mapping (Look for communicationStageKey)
                            final commKey = (childData['communicationStageKey'] ?? '').toString();
                            final commValue = commKey.isEmpty ? t.t('not_set') : t.t(commKey);

                            // 3. Safe Birthday Parsing (Prevents Red Screen)
                            String dobStr = t.t('not_set');
                            var rawDob = childData['dateOfBirth'];
                            if (rawDob != null) {
                              if (rawDob is Timestamp) {
                                final dt = rawDob.toDate();
                                dobStr = "${dt.day}.${dt.month}.${dt.year}";
                              } else if (rawDob is String) {
                                dobStr = rawDob; // Uses the string from your database
                              }
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBlue,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Icon(
                                      Icons.child_care,
                                      color: AppColors.textDark,
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (username.isNotEmpty)
                                    Text(
                                      '@$username',
                                      style: const TextStyle(color: AppColors.textSoft, fontSize: 13),
                                    ),

                                  const SizedBox(height: 24),

                                  // Information Rows
                                  _RowInfo(label: t.t('date_of_birth'), value: dobStr),
                                  _RowInfo(label: t.t('goal'), value: goalValue),
                                  _RowInfo(label: t.t('communication'), value: commValue),

                                  const Spacer(),

                                  // Parent Lock Footer
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock, size: 16, color: AppColors.textDark),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.t('parent_only_change_msg'),
                                          style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  const _RowInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}