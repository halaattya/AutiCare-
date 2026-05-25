// lib/screens/parents/parent_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../ui/app_colors.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/app_localizations.dart';

import 'add_child_screen.dart';
import 'link_child_screen.dart';
import 'weekly_report_screen.dart';
import 'daily_log_screen.dart';

// ✅ NEW: Parent-side child profile screen (we will create it next)
import 'parent_child_profile_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  void _showLanguageSheet(BuildContext context) {
    final t = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final current = localeController.locale.languageCode;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('choose_language'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              RadioListTile<String>(
                value: 'en',
                groupValue: current,
                title: Text(t.t('english')),
                onChanged: (_) {
                  localeController.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                value: 'ar',
                groupValue: current,
                title: Text(t.t('arabic')),
                onChanged: (_) {
                  localeController.setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isAr = t.locale.languageCode == 'ar';

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(t.t('not_signed_in'))),
      );
    }

    final uid = user.uid;

    final childrenStream = FirebaseFirestore.instance
        .collection('children')
        .where('linkedAdults', arrayContains: uid)
        .snapshots();

    final parentDocStream =
        FirebaseFirestore.instance.collection('parents').doc(uid).snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: Text(
          t.t('parent_space'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            tooltip: t.t('language'),
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageSheet(context),
          ),
          IconButton(
            tooltip: t.t('logout'),
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'link',
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.link),
            label: Text(t.t('link_child')),
            onPressed: () async {
              final linked = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LinkChildScreen()),
              );
              if (linked == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم ربط الطفل ✅' : 'Child linked ✅'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add',
            backgroundColor: AppColors.accentPeach,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(t.t('add_child')),
            onPressed: () async {
              final added = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddChildScreen()),
              );
              if (added == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تمت إضافة الطفل ✅' : 'Child added ✅'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.t('track_with_love'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.t('track_with_love_sub'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Weekly report
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardPeach,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 28, color: AppColors.textDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'فتح التقرير الأسبوعي (مخططات + تفاصيل)'
                              : 'Open Weekly Report (Charts + Details)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Daily log
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLavender,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyLogScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_rounded,
                          size: 28, color: AppColors.textDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.t('open_daily_log'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                t.t('your_children'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // Children list
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: parentDocStream,
                  builder: (context, parentSnap) {
                    final parentData =
                        parentSnap.data?.data() as Map<String, dynamic>?;
                    final activeChildId =
                        parentData?['activeChildId']?.toString();

                    return StreamBuilder<QuerySnapshot>(
                      stream: childrenStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              isAr
                                  ? 'لا يوجد أطفال بعد.\nاستخدمي "إضافة طفل" أو "ربط طفل".'
                                  : 'No children yet.\nUse "Add child" or "Link child".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final name = (data['name'] ?? 'Child').toString();

                            // Keys saved in AddChildScreen
                            final goalKey = data['mainGoalAreaKey']?.toString();
                            final commKey =
                                data['communicationStageKey']?.toString();

                            final goal = (goalKey != null && goalKey.isNotEmpty)
                                ? t.t(goalKey)
                                : (data['goalArea'] ?? '—').toString();

                            final comm = (commKey != null && commKey.isNotEmpty)
                                ? t.t(commKey)
                                : (data['communicationLevel'] ?? '—').toString();

                            final username = (data['username'] ?? '').toString();
                            final isActive = activeChildId == doc.id;

                            final colors = [
                              AppColors.cardLight,
                              AppColors.cardBlue,
                              AppColors.cardLavender,
                            ];
                            final color = colors[index % colors.length];

                            return InkWell(
                              borderRadius: BorderRadius.circular(24),

                              // ✅ Keep your existing behavior:
                              // Tap anywhere on the card -> set active child.
                              onTap: () async {
                                await FirebaseFirestore.instance
                                    .collection('parents')
                                    .doc(uid)
                                    .set({'activeChildId': doc.id},
                                        SetOptions(merge: true));

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? 'تم تحديد الطفل النشط: $name ✅'
                                            : 'Active child set: $name ✅',
                                      ),
                                    ),
                                  );
                                }
                              },

                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(24),
                                  border: isActive
                                      ? Border.all(
                                          color: AppColors.textDark, width: 2)
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.child_care,
                                          color: AppColors.textDark),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ),
                                              if (isActive)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    t.t('active'),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isAr ? 'الهدف: $goal' : 'Goal: $goal',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSoft,
                                            ),
                                          ),
                                          Text(
                                            isAr
                                                ? 'التواصل: $comm'
                                                : 'Communication: $comm',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSoft,
                                            ),
                                          ),
                                          if (username.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              isAr
                                                  ? 'رمز الربط: $username'
                                                  : 'Link code: $username',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // ✅ NEW (Option A):
                                    // Small "Profile" button that opens the child profile screen.
                                    // This does NOT affect the InkWell onTap.
                                    IconButton(
                                      tooltip: isAr ? 'الملف الشخصي' : 'Profile',
                                      icon: const Icon(
                                        Icons.person_outline,
                                        color: AppColors.textSoft,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ParentChildProfileScreen(
                                              childId: doc.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
