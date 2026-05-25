import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocDelegate();

  static const Map<String, Map<String, String>> _strings = {
    // ================= General =================
    'app_name': {'en': 'Autism App', 'ar': 'تطبيق التوحّد'},
    'language': {'en': 'Language', 'ar': 'اللغة'},
    'english': {'en': 'English', 'ar': 'الإنجليزية'},
    'arabic': {'en': 'Arabic', 'ar': 'العربية'},
    'choose_language': {'en': 'Choose language', 'ar': 'اختيار اللغة'},

    'optional': {'en': 'Optional', 'ar': 'اختياري'},
    'choose_one': {'en': 'Choose one', 'ar': 'اختر خيارًا'},
    'tap_to_select': {'en': 'Tap to select', 'ar': 'اضغطي للاختيار'},
    'not_set': {'en': 'Not set', 'ar': 'غير محدد'},
    'dash': {'en': '—', 'ar': '—'},
    'yes': {'en': 'Yes', 'ar': 'نعم'},
    'no': {'en': 'No', 'ar': 'لا'},
    'edit': {'en': 'Edit', 'ar': 'تعديل'},

// ================= Parent Auth (NEW) =================
'parent_login_title': {'en': 'Parent login', 'ar': 'تسجيل دخول الأهل'},
'parent_signup_title': {'en': 'Create parent account', 'ar': 'إنشاء حساب للأهل'},

'field_email': {'en': 'Email', 'ar': 'البريد الإلكتروني'},
'field_password': {'en': 'Password', 'ar': 'كلمة المرور'},

'btn_login': {'en': 'Log in', 'ar': 'تسجيل الدخول'},
'btn_signup': {'en': 'Sign up', 'ar': 'إنشاء حساب'},

'toggle_create_account': {'en': 'Create a new account', 'ar': 'إنشاء حساب جديد'},
'toggle_have_account': {'en': 'I already have an account', 'ar': 'لدي حساب بالفعل'},

'err_email_pass_invalid': {
  'en': 'Please enter a valid email and a password (6+ characters).',
  'ar': 'يرجى إدخال بريد إلكتروني صحيح وكلمة مرور (٦ أحرف أو أكثر).'
},
'err_auth_failed': {
  'en': 'Authentication failed. Please try again.',
  'ar': 'فشل تسجيل الدخول. حاول مرة أخرى.'
},
 // ================= Can Read (NEW) =================
'can_read_question': {
  'en': 'Can read?',
  'ar': 'هل يستطيع القراءة؟'
},

    // ================= Initializer =================
    'loading_world': {'en': 'Loading your world...', 'ar': 'جاري تحميل عالمك...'},
    'firebase_error': {
      'en': 'Firebase Error. Please check internet.',
      'ar': 'خطأ في Firebase. تأكد من الاتصال بالإنترنت.'
    },

    // ================= Home =================
    'hello': {'en': 'Hello!', 'ar': 'مرحباً!'},
    'communication': {'en': 'Communication', 'ar': 'التواصل'},
    'cognitive': {'en': 'Cognitive', 'ar': 'الإدراك'},
    'attention': {'en': 'Attention', 'ar': 'الانتباه'},
    'calm_corner': {'en': 'Calm Corner', 'ar': 'ركن الهدوء'},
    'play': {'en': 'Play', 'ar': 'ابدأ'},

    // ================= Bottom Nav =================
    'nav_home': {'en': 'Home', 'ar': 'الرئيسية'},
    'nav_games': {'en': 'Games', 'ar': 'الألعاب'},
    'nav_parents': {'en': 'Parents', 'ar': 'الأهل'},

    // ================= Games =================
    'games': {'en': 'Games', 'ar': 'الألعاب'},
    'sec_comm_games': {'en': 'Communication Games', 'ar': 'ألعاب التواصل'},
    'sec_cog_games': {'en': 'Cognitive Games', 'ar': 'ألعاب الإدراك'},
    'sec_attention': {'en': 'Attention & Focus', 'ar': 'التركيز والانتباه'},
    'sec_calm': {'en': 'Calm Corner Activities', 'ar': 'أنشطة ركن الهدوء'},
    'matching_pictures': {'en': 'Matching Pictures', 'ar': 'مطابقة الصور'},
    'sound_matching': {'en': 'Sound Matching', 'ar': 'مطابقة الأصوات'},
    'memory_game': {'en': 'Memory Game', 'ar': 'لعبة الذاكرة'},
    'sorting_game': {'en': 'Sorting Game', 'ar': 'لعبة الفرز'},
    'shape_matching': {'en': 'Shape Matching', 'ar': 'مطابقة الأشكال'},
    'tap_target': {'en': 'Tap the Target', 'ar': 'اضغط على الهدف'},
    'find_object': {'en': 'Find the Object', 'ar': 'ابحث عن الشيء'},
    'pop_balloon': {'en': 'Pop the Balloon', 'ar': 'فرقع البالون'},
    'reaction_time': {'en': 'Reaction Time Game', 'ar': 'زمن الاستجابة'},
    'breathing': {'en': 'Breathing Exercise', 'ar': 'تمرين التنفس'},
    'calming_sounds': {'en': 'Calming Sounds', 'ar': 'أصوات مهدئة'},
    'bubble_pop': {'en': 'Bubble Pop Relax', 'ar': 'فقاعات الاسترخاء'},
    'coming_soon': {'en': 'Coming soon 🙂', 'ar': 'قريباً 🙂'},

    // ================= Parent Dashboard (keys used in UI) =================
    'parent_space': {'en': 'Parent Space', 'ar': 'مساحة الأهل'},
    'logout': {'en': 'Log out', 'ar': 'تسجيل الخروج'},
    'link_child': {'en': 'Link child', 'ar': 'ربط طفل'},
    'add_child': {'en': 'Add child', 'ar': 'إضافة طفل'},
    'your_children': {'en': 'Your children', 'ar': 'أطفالك'},
    'active': {'en': 'ACTIVE', 'ar': 'نشط'},
    'not_signed_in': {'en': 'Not signed in', 'ar': 'غير مسجل الدخول'},

    // ================= Track with Love =================
    'track_with_love': {'en': 'Track with love 💛', 'ar': 'تابع بمحبة 💛'},
    'track_with_love_sub': {
      'en': 'Daily logs and weekly insights to understand patterns.',
      'ar': 'سجل يومي وملخصات أسبوعية لفهم الأنماط.'
    },
    'open_daily_log': {
      'en': 'Open Daily Log (Sleep • Mood • Triggers)',
      'ar': 'فتح السجل اليومي (النوم • المزاج • المحفزات)'
    },

    // ================= Link Child =================
    'link_child_title': {'en': 'Link child', 'ar': 'ربط طفل'},
    'link_child_info': {
      'en': 'Enter the child username provided by the parent.',
      'ar': 'أدخل اسم مستخدم الطفل الذي زوّدك به الأهل.'
    },
    'field_child_username_example': {
      'en': 'Child username (e.g. sara_8FQ)',
      'ar': 'اسم مستخدم الطفل (مثال: sara_8FQ)'
    },
    'btn_link': {'en': 'Link', 'ar': 'ربط'},

    // ================= Add Child =================
    'add_child_profile_title': {'en': 'Add child profile', 'ar': 'إضافة ملف طفل'},
    'add_child_info_username': {
      'en': 'A unique link username will be generated automatically.',
      'ar': 'سيتم إنشاء اسم مستخدم فريد للربط تلقائيًا.'
    },
    'field_child_name_required': {'en': 'Child name *', 'ar': 'اسم الطفل *'},
    'btn_save_child_profile': {'en': 'Save child profile', 'ar': 'حفظ ملف الطفل'},
    'date_of_birth': {'en': 'Date of birth', 'ar': 'تاريخ الميلاد'},

    // ================= Errors =================
    'err_enter_valid_username': {'en': 'Please enter a valid username', 'ar': 'يرجى إدخال اسم مستخدم صالح'},
    'err_username_not_found': {'en': 'Username not found', 'ar': 'اسم المستخدم غير موجود'},
    'err_failed_link_child': {'en': 'Failed to link child. Try again.', 'ar': 'فشل ربط الطفل. حاول مرة أخرى.'},
    'err_enter_child_name': {'en': 'Please enter the child name', 'ar': 'يرجى إدخال اسم الطفل'},
    'err_failed_add_child': {'en': 'Failed to add child. Try again.', 'ar': 'فشل إضافة الطفل. حاول مرة أخرى.'},

    // ================= Child Profile =================
    'child_profile': {'en': 'Child profile', 'ar': 'ملف الطفل'},
    'child': {'en': 'Child', 'ar': 'طفل'},
    'ask_parent_sign_in': {'en': 'Please ask a parent to sign in.', 'ar': 'يرجى من أحد الأهل تسجيل الدخول.'},
    'active_child_desc': {'en': 'This is the currently active child profile.', 'ar': 'هذا هو ملف الطفل النشط حاليًا.'},
    'goal': {'en': 'Goal', 'ar': 'الهدف'},
    'communication_label': {'en': 'Communication', 'ar': 'التواصل'},
    'only_parents_change': {'en': 'Only parents can change child information.', 'ar': 'فقط الأهل يمكنهم تعديل معلومات الطفل.'},
    'no_active_child': {'en': 'No active child', 'ar': 'لا يوجد طفل نشط'},
    'ask_parent_select_active': {'en': 'Please ask a parent to select an active child.', 'ar': 'يرجى من الأهل اختيار طفل نشط.'},

    // ✅✅✅ ADDED KEYS to match what your UI is showing in the screenshot
    'child_profile_title': {'en': 'Child profile', 'ar': 'ملف الطفل'},
    'profile_info_msg': {'en': 'Only parents can change child information.', 'ar': 'فقط الأهل يمكنهم تعديل معلومات الطفل.'},
    'parent_only_change_msg': {'en': 'Only parents can change child information.', 'ar': 'فقط الأهل يمكنهم تعديل معلومات الطفل.'},
    // ✅✅✅ end added keys

    // ================= Add Child (Extended fields) =================
    'communication_stage': {'en': 'Communication stage', 'ar': 'مرحلة التواصل'},
    'main_goal_area': {'en': 'Main goal area', 'ar': 'مجال الهدف الرئيسي'},
    'support_needs_level': {'en': 'Support needs level', 'ar': 'مستوى الاحتياج للدعم'},

    // Support needs levels (dropdown values)
    'support_1': {'en': 'Level 1 (low support)', 'ar': 'المستوى 1 (دعم منخفض)'},
    'support_2': {'en': 'Level 2 (moderate support)', 'ar': 'المستوى 2 (دعم متوسط)'},
    'support_3': {'en': 'Level 3 (high support)', 'ar': 'المستوى 3 (دعم عالي)'},

    // Communication stages (dropdown values)
    'comm_preverbal': {'en': 'Pre-verbal', 'ar': 'قبل الكلام'},
    'comm_single_words': {'en': 'Single words', 'ar': 'كلمات مفردة'},
    'comm_short_sentences': {'en': 'Short sentences', 'ar': 'جمل قصيرة'},
    'comm_full_sentences': {'en': 'Full sentences', 'ar': 'جمل كاملة'},

    // Main goal area (dropdown values)
    'goal_communication': {'en': 'Communication', 'ar': 'التواصل'},
    'goal_cognitive': {'en': 'Cognitive', 'ar': 'الإدراك'},
    'goal_attention': {'en': 'Attention', 'ar': 'الانتباه'},
    'goal_emotional': {'en': 'Emotional regulation', 'ar': 'تنظيم المشاعر'},

    // Sensory sensitivities (chips)
    'sensory_sensitivities': {'en': 'Sensory sensitivities', 'ar': 'الحساسيات الحسية'},
    'sens_bright_lights': {'en': 'Bright lights', 'ar': 'أضواء ساطعة'},
    'sens_loud_sounds': {'en': 'Loud sounds', 'ar': 'أصوات عالية'},
    'sens_crowded_places': {'en': 'Crowded places', 'ar': 'أماكن مزدحمة'},
    'sens_touch': {'en': 'Touch / clothing', 'ar': 'اللمس / الملابس'},
    'sens_no_strong': {'en': 'No strong sensitivities', 'ar': 'لا توجد حساسيات قوية'},

    // Primary challenges (chips)
    'primary_challenges': {'en': 'Primary challenges', 'ar': 'التحديات الرئيسية'},
    'ch_communication': {'en': 'Communication', 'ar': 'التواصل'},
    'ch_attention_focus': {'en': 'Attention & focus', 'ar': 'التركيز والانتباه'},
    'ch_social_interaction': {'en': 'Social interaction', 'ar': 'التفاعل الاجتماعي'},
    'ch_emotional_regulation': {'en': 'Emotional regulation', 'ar': 'تنظيم المشاعر'},
    'ch_motor_coordination': {'en': 'Motor coordination', 'ar': 'التنسيق الحركي'},

    // Strengths & interests (chips)
    'strengths_interests': {'en': 'Strengths & interests', 'ar': 'نقاط القوة والاهتمامات'},
    'st_patterns': {'en': 'Patterns', 'ar': 'الأنماط'},
    'st_music': {'en': 'Music', 'ar': 'الموسيقى'},
    'st_visual_learning': {'en': 'Visual learning', 'ar': 'التعلم البصري'},
    'st_routine': {'en': 'Routine', 'ar': 'الروتين'},
    'st_movement': {'en': 'Movement', 'ar': 'الحركة'},

    // ================= Daily Log (Screen) =================
    'daily_log': {'en': 'Daily Log', 'ar': 'السجل اليومي'},
    'pick_date': {'en': 'Pick date', 'ar': 'اختيار التاريخ'},
    'day_snapshot': {'en': 'Day snapshot', 'ar': 'نظرة سريعة على اليوم'},
    'date': {'en': 'Date', 'ar': 'التاريخ'},
    'tap_calendar': {'en': 'Tap calendar ↑', 'ar': 'اضغطي على التقويم ↑'},
    'overall_day_rating_optional': {'en': 'Overall day rating (optional)', 'ar': 'تقييم اليوم بشكل عام (اختياري)'},
    'sleep_routine': {'en': 'Sleep & routine', 'ar': 'النوم والروتين'},
    'sleep_hours': {'en': 'Sleep hours', 'ar': 'ساعات النوم'},
    'sleep_hours_hint': {'en': 'e.g. 7.5', 'ar': 'مثال: 7.5'},
    'sleep_quality': {'en': 'Sleep quality', 'ar': 'جودة النوم'},
    'nap_taken': {'en': 'Nap taken', 'ar': 'أخذ قيلولة'},
    'routine_changed_today': {'en': 'Routine changed today?', 'ar': 'هل تغيّر الروتين اليوم؟'},
    'what_changed': {'en': 'What changed?', 'ar': 'ماذا تغيّر؟'},
    'describe_change': {'en': 'Describe the change', 'ar': 'صفّي التغيير'},
    'short_description': {'en': 'Short description', 'ar': 'وصف قصير'},

    'mood_emotional': {'en': 'Mood & emotional state', 'ar': 'المزاج والحالة العاطفية'},
    'main_mood': {'en': 'Main mood', 'ar': 'المزاج الأساسي'},
    'mood_intensity_optional': {'en': 'Mood intensity (optional)', 'ar': 'شدة المزاج (اختياري)'},
    'mood_intensity_subtitle': {'en': '1 = very low, 10 = very intense', 'ar': '1 = منخفض جدًا، 10 = شديد جدًا'},
    'meltdown_count': {'en': 'Meltdown count', 'ar': 'عدد نوبات الانهيار'},

    'behaviors_observed': {'en': 'Behaviors observed', 'ar': 'السلوكيات الملحوظة'},
    'triggers': {'en': 'Triggers', 'ar': 'المحفزات'},
    'other': {'en': 'Other', 'ar': 'أخرى'},
    'other_trigger': {'en': 'Other trigger', 'ar': 'محفز آخر'},
    'write_trigger': {'en': 'Write the trigger', 'ar': 'اكتب المحفز'},

    'calming_strategies': {'en': 'Calming strategies used', 'ar': 'استراتيجيات التهدئة المستخدمة'},
    'other_calming_strategy': {'en': 'Other calming strategy', 'ar': 'استراتيجية تهدئة أخرى'},
    'write_what_helped': {'en': 'Write what helped', 'ar': 'اكتب ما الذي ساعد'},
    'effectiveness': {'en': 'Effectiveness', 'ar': 'مدى الفعالية'},

    'skills_therapy_optional': {'en': 'Skills / therapy (optional)', 'ar': 'مهارات / علاج (اختياري)'},
    'communication_practice_today': {'en': 'Communication practice today?', 'ar': 'تدريب على التواصل اليوم؟'},
    'social_interaction': {'en': 'Social interaction', 'ar': 'التفاعل الاجتماعي'},
    'therapy_session_today': {'en': 'Therapy session today?', 'ar': 'جلسة علاج اليوم؟'},
    'therapy_type': {'en': 'Therapy type', 'ar': 'نوع العلاج'},
    'other_therapy': {'en': 'Other therapy', 'ar': 'علاج آخر'},
    'write_type': {'en': 'Write type', 'ar': 'اكتب النوع'},

    'parent_focus_target_optional': {'en': 'Parent focus target (optional)', 'ar': 'هدف تركيز الأهل (اختياري)'},
    'focus_target': {'en': 'Focus target', 'ar': 'هدف التركيز'},
    'write_focus_target': {'en': 'Write your focus target', 'ar': 'اكتب هدف التركيز'},
    'short_goal': {'en': 'Short goal', 'ar': 'هدف قصير'},

    'notes_optional': {'en': 'Notes (optional)', 'ar': 'ملاحظات (اختياري)'},
    'notes_hint': {
      'en': 'Anything important today? doctor visit, school event, etc.',
      'ar': 'هل حدث شيء مهم اليوم؟ زيارة طبيب، فعالية مدرسية، إلخ.'
    },

    // ================= Buttons =================
    'done_check': {'en': 'Done ✓', 'ar': 'تم ✓'},

    // ===== Daily Log values (keep stored values in English; display translated) =====
    'sq_good': {'en': 'Good', 'ar': 'جيدة'},
    'sq_okay': {'en': 'Okay', 'ar': 'متوسطة'},
    'sq_poor': {'en': 'Poor', 'ar': 'ضعيفة'},

    'rc_school': {'en': 'School', 'ar': 'المدرسة'},
    'rc_travel': {'en': 'Travel', 'ar': 'سفر'},
    'rc_guests': {'en': 'Guests', 'ar': 'ضيوف'},
    'rc_new_place': {'en': 'New place', 'ar': 'مكان جديد'},

    'mood_calm': {'en': 'Calm', 'ar': 'هادئ'},
    'mood_okay': {'en': 'Okay', 'ar': 'عادي'},
    'mood_anxious': {'en': 'Anxious', 'ar': 'قلق'},
    'mood_overwhelmed': {'en': 'Overwhelmed', 'ar': 'مرهق/متوتر'},
    'mood_meltdown': {'en': 'Meltdown', 'ar': 'انهيار'},

    'eff_worked_well': {'en': 'Worked well', 'ar': 'مفيدة جدًا'},
    'eff_worked_bit': {'en': 'Worked a bit', 'ar': 'مفيدة قليلًا'},
    'eff_didnt_help': {'en': 'Didn’t help', 'ar': 'لم تساعد'},

    'si_none': {'en': 'None', 'ar': 'لا يوجد'},
    'si_small': {'en': 'Small', 'ar': 'قليل'},
    'si_good': {'en': 'Good', 'ar': 'جيد'},

    'th_speech': {'en': 'Speech', 'ar': 'علاج نطق'},
    'th_aba': {'en': 'ABA', 'ar': 'ABA'},
    'th_ot': {'en': 'OT', 'ar': 'علاج وظيفي'},

    'bh_hyperactive': {'en': 'Hyperactive', 'ar': 'فرط حركة'},
    'bh_aggressive': {'en': 'Aggressive', 'ar': 'عدوانية'},
    'bh_withdrawal': {'en': 'Withdrawal', 'ar': 'انسحاب'},
    'bh_repetitive': {'en': 'Repetitive behavior', 'ar': 'سلوك تكراري'},
    'bh_sens_seek': {'en': 'Sensory seeking', 'ar': 'بحث عن الإحساس'},
    'bh_sens_avoid': {'en': 'Sensory avoidance', 'ar': 'تجنب الإحساس'},
    'bh_eye_contact': {'en': 'Good eye contact', 'ar': 'تواصل بصري جيد'},
    'bh_good_comm': {'en': 'Good communication', 'ar': 'تواصل جيد'},

    'tr_loud': {'en': 'Loud sounds', 'ar': 'أصوات عالية'},
    'tr_crowds': {'en': 'Crowds', 'ar': 'ازدحام'},
    'tr_change_routine': {'en': 'Change in routine', 'ar': 'تغيير في الروتين'},
    'tr_transitions': {'en': 'Transitions', 'ar': 'الانتقالات'},
    'tr_hunger': {'en': 'Hunger', 'ar': 'جوع'},
    'tr_fatigue': {'en': 'Fatigue', 'ar': 'تعب'},
    'tr_new_person': {'en': 'New person', 'ar': 'شخص جديد'},
    'tr_screen_time': {'en': 'Screen time', 'ar': 'وقت الشاشة'},
    'tr_touch_clothes': {'en': 'Touch / clothing', 'ar': 'اللمس / الملابس'},

    'cal_deep_breath': {'en': 'Deep breathing', 'ar': 'تنفس عميق'},
    'cal_music': {'en': 'Music', 'ar': 'موسيقى'},
    'cal_quiet_space': {'en': 'Quiet space', 'ar': 'مكان هادئ'},
    'cal_weighted_blanket': {'en': 'Weighted blanket', 'ar': 'بطانية ثقيلة'},
    'cal_sensory_toy': {'en': 'Sensory toy', 'ar': 'لعبة حسية'},
    'cal_walk': {'en': 'Walk / movement', 'ar': 'مشي / حركة'},
    'cal_visual_schedule': {'en': 'Visual schedule', 'ar': 'جدول بصري'},
    'cal_hug': {'en': 'Hug / comfort', 'ar': 'حضن / تهدئة'},
    'cal_snack_water': {'en': 'Snack / water', 'ar': 'وجبة خفيفة / ماء'},

    'ft_follow': {'en': 'Follow instructions', 'ar': 'اتباع التعليمات'},
    'ft_reduce_meltdowns': {'en': 'Reduce meltdowns', 'ar': 'تقليل نوبات الانهيار'},
    'ft_eye_contact': {'en': 'Improve eye contact', 'ar': 'تحسين التواصل البصري'},
    'ft_transitions': {'en': 'Improve transitions', 'ar': 'تحسين الانتقالات'},
    'ft_words_not_screaming': {'en': 'Use words instead of screaming', 'ar': 'استخدام الكلمات بدل الصراخ'},
    'ft_calm_public': {'en': 'Stay calm in public', 'ar': 'الهدوء في الأماكن العامة'},

    // ================= Daily Log Summary =================
    'daily_log_summary': {'en': 'Daily Log Summary', 'ar': 'ملخص السجل اليومي'},
    'daily_log_card_title': {'en': 'Daily Log —', 'ar': 'السجل اليومي —'},
    'day_rating': {'en': 'Day rating', 'ar': 'تقييم اليوم'},
    'sleep': {'en': 'Sleep', 'ar': 'النوم'},
    'sleep_quality_label': {'en': 'Sleep quality', 'ar': 'جودة النوم'},
    'nap': {'en': 'Nap', 'ar': 'قيلولة'},
    'routine_changed': {'en': 'Routine changed', 'ar': 'تغير الروتين'},
    'routine_change': {'en': 'Routine change', 'ar': 'نوع التغيير'},
    'routine_other': {'en': 'Routine other', 'ar': 'تفاصيل التغيير'},

    'mood': {'en': 'Mood', 'ar': 'المزاج'},
    'mood_intensity': {'en': 'Mood intensity', 'ar': 'شدة المزاج'},
    'meltdowns': {'en': 'Meltdowns', 'ar': 'نوبات الانهيار'},

    'behaviors': {'en': 'Behaviors', 'ar': 'السلوكيات'},
    'trigger_other': {'en': 'Trigger other', 'ar': 'محفز آخر'},
    'calming': {'en': 'Calming', 'ar': 'التهدئة'},
    'calming_other': {'en': 'Calming other', 'ar': 'تهدئة أخرى'},
    'effectiveness_label': {'en': 'Effectiveness', 'ar': 'الفعالية'},

    'communication_practice': {'en': 'Communication practice', 'ar': 'تدريب التواصل'},
    'therapy_today': {'en': 'Therapy today', 'ar': 'جلسة علاج اليوم'},
    'therapy_type_label': {'en': 'Therapy type', 'ar': 'نوع العلاج'},
    'therapy_other': {'en': 'Therapy other', 'ar': 'علاج آخر'},

    'focus_target_label': {'en': 'Focus target', 'ar': 'هدف التركيز'},
    'focus_other': {'en': 'Focus other', 'ar': 'هدف آخر'},
    'notes': {'en': 'Notes', 'ar': 'ملاحظات'},

    // ================= Weekly Report =================
    'weekly_report': {'en': 'Weekly Report (Last 7 Days)', 'ar': 'التقرير الأسبوعي (آخر 7 أيام)'},
    'no_active_child_selected': {'en': 'No active child selected.', 'ar': 'لم يتم اختيار طفل نشط.'},
    'no_sessions_last_7': {
      'en': 'No sessions in the last 7 days. Play a game then come back.',
      'ar': 'لا توجد جلسات خلال آخر 7 أيام. العبوا لعبة ثم ارجعوا هنا.'
    },
    'weekly_summary': {'en': 'Weekly Summary', 'ar': 'الملخص الأسبوعي'},
    'tap_game_card_expand': {
      'en': 'Tap any game card to expand details and session list.',
      'ar': 'اضغطي على أي لعبة لعرض التفاصيل وقائمة الجلسات.'
    },
    'total_play': {'en': 'Total play', 'ar': 'إجمالي اللعب'},
    'favorite': {'en': 'Favorite', 'ar': 'المفضلة'},
    'most_dropped': {'en': 'Most dropped', 'ar': 'الأكثر تركًا'},
    'plays': {'en': 'Plays', 'ar': 'عدد المرات'},
    'dropped': {'en': 'Dropped', 'ar': 'تم تركها'},
    'time': {'en': 'Time', 'ar': 'الوقت'},
    'completion': {'en': 'Completion', 'ar': 'الإكمال'},
    'avg': {'en': 'Avg', 'ar': 'المعدل'},
    'lower_better': {'en': 'lower better', 'ar': 'الأقل أفضل'},
    'latest_sessions_proof': {'en': 'Latest Sessions (proof)', 'ar': 'آخر الجلسات (دليل)'},
    'duration': {'en': 'Duration', 'ar': 'المدة'},
    'primary': {'en': 'Primary', 'ar': 'المؤشر الأساسي'},

    // ================= Daily Log Info (embedded bar) =================
    'daily_log_info_title': {'en': 'Why the Daily Log matters', 'ar': 'لماذا السجل اليومي مهم؟'},
    'dli_what_log_does': {'en': 'What this log does', 'ar': 'ماذا يفعل هذا السجل'},
    'dli_how_to_use': {'en': 'How to use it (2 minutes/day)', 'ar': 'كيفية استخدامه (دقيقتان يوميًا)'},
    'dli_why_doctors': {'en': 'Why doctors/therapists love it', 'ar': 'لماذا يحبّه الأطباء والمعالجون'},
    'dli_privacy': {'en': 'Privacy', 'ar': 'الخصوصية'},

    'dli_b1': {
      'en': 'Turns daily observations into clear patterns over time.',
      'ar': 'يحوّل الملاحظات اليومية إلى أنماط واضحة مع الوقت.'
    },
    'dli_b2': {
      'en': 'Helps identify triggers and what calming methods work best.',
      'ar': 'يساعد على تحديد المحفزات ومعرفة أفضل طرق التهدئة.'
    },
    'dli_b3': {
      'en': 'Explains why some days show better progress in games than others.',
      'ar': 'يوضح لماذا بعض الأيام يظهر فيها تقدّم أفضل في الألعاب.'
    },

    'dli_b4': {'en': 'Fill only what you know — nothing is mandatory.', 'ar': 'عبّ فقط ما تعرفينه — لا شيء إلزامي.'},
    'dli_b5': {'en': 'Pick mood + triggers + calming strategies.', 'ar': 'اختار المزاج + المحفزات + استراتيجيات التهدئة.'},
    'dli_b6': {'en': 'Add a short note if something important happened.', 'ar': 'أضيف ملاحظة قصيرة إذا حدث شيء مهم.'},

    'dli_b7': {
      'en': 'Gives real evidence instead of memory-based guesses.',
      'ar': 'يعطي دليلًا حقيقيًا بدل التخمين اعتمادًا على الذاكرة.'
    },
    'dli_b8': {
      'en': 'Shows sleep, mood, triggers, and patterns across weeks.',
      'ar': 'يعرض النوم والمزاج والمحفزات والأنماط عبر أسابيع.'
    },
    'dli_b9': {'en': 'Makes checkups faster and more accurate.', 'ar': 'يجعل المتابعة أسرع وأكثر دقة.'},

    'dli_b10': {'en': 'Logs are stored under the child profile securely.', 'ar': 'يتم حفظ السجلات بأمان ضمن ملف الطفل.'},
    'dli_b11': {'en': 'Only linked adults can access the child data.', 'ar': 'فقط البالغون المرتبطون يمكنهم الوصول لبيانات الطفل.'},
   
   // ================= Parent Child Profile (NEW) =================
'profile': {'en': 'Profile', 'ar': 'الملف الشخصي'},
'save': {'en': 'Save', 'ar': 'حفظ'},
'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},

'current_levels': {'en': 'Current Levels', 'ar': 'المستويات الحالية'},
'app_level': {'en': 'App level', 'ar': 'مستوى التطبيق'},

'child_information': {'en': 'Child information', 'ar': 'معلومات الطفل'},
'age': {'en': 'Age', 'ar': 'العمر'},

'selections': {'en': 'Selections', 'ar': 'الاختيارات'},
'can_read': {'en': 'Can read?', 'ar': 'هل يستطيع القراءة؟'},

'link_code': {'en': 'Link code', 'ar': 'رمز الربط'},

'levels_auto_update_note': {
  'en': 'These levels update automatically based on the child’s performance in the games.',
  'ar': 'هذه المستويات تتحدث تلقائياً حسب أداء الطفل داخل الألعاب.'
},
// ================= Attention Span (NEW) =================
'attention_span': {'en': 'Attention span', 'ar': 'مدة الانتباه'},
'att_lt_1': {'en': 'Less than 1 minute', 'ar': 'أقل من دقيقة'},
'att_1_3': {'en': '1–3 minutes', 'ar': '1–3 دقائق'},
'att_3_5': {'en': '3–5 minutes', 'ar': '3–5 دقائق'},
'att_5_10': {'en': '5–10 minutes', 'ar': '5–10 دقائق'},
'att_10_plus': {'en': '10+ minutes', 'ar': 'أكثر من 10 دقائق'},
// ================= Extra chips (NEW) =================
'sens_food_textures': {'en': 'Food textures', 'ar': 'ملمس الطعام'},
'sens_smells': {'en': 'Smells', 'ar': 'الروائح'},
// ================= Daily Readiness (NEW) =================
'ready_title': {'en': 'Today’s readiness', 'ar': 'جاهزية اليوم'},
'ready_low': {'en': 'Low', 'ar': 'منخفضة'},
'ready_medium': {'en': 'Medium', 'ar': 'متوسطة'},
'ready_high': {'en': 'High', 'ar': 'مرتفعة'},

'ready_rec_random': {'en': 'Random play', 'ar': 'لعب عشوائي'},
'ready_rec_calm': {'en': 'calm activities', 'ar': 'أنشطة هادئة'},
'ready_rec_familiar': {'en': 'familiar games', 'ar': 'ألعاب مألوفة'},
'ready_rec_challenge': {'en': 'a bit more challenge', 'ar': 'تحدّي أكثر قليلاً'},

'ready_note_prefix': {'en': 'Based on today’s log, readiness looks', 'ar': 'بناءً على سجل اليوم، تبدو الجاهزية'},
'ready_note_mid': {'en': '— recommending', 'ar': '— ويوصي بـ'},

'ready_btn_random_on': {
  'en': 'Random play is ON',
  'ar': 'اللعب العشوائي مُفعل'
},
'ready_btn_random_off': {
  'en': 'Keep smart recommendation',
  'ar': 'استخدم التوصية الذكية'
},

// ================= PDF Preview (NEW) =================
'pdf_daily_log_title': {'en': 'Daily Log PDF', 'ar': 'PDF السجل اليومي'},

// ================= Weekly Report PDF =================
'pdf_weekly_report_title': {
  'en': 'Weekly Report PDF',
  'ar': 'PDF التقرير الأسبوعي'
},
'back': {
  'en': 'Back',
  'ar': 'رجوع'
},



'ch_transition_change': {'en': 'Transitions & change', 'ar': 'الانتقال والتغيير'},
'ch_sensory_overload': {'en': 'Sensory overload', 'ar': 'فرط التحفيز الحسي'},

   
   };

  String t(String key) {
    final code = locale.languageCode;
    return _strings[key]?[code] ?? _strings[key]?['en'] ?? key;
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
