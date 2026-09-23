import 'package:flutter/material.dart';

/// Lightweight, dependency-free localisation for Mizan.
///
/// Only the two languages the app ships with (English + Arabic) are needed,
/// so a hand-written lookup table keeps things fast and avoids code
/// generation while still supporting full RTL layout.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  String _get(String key) {
    final table = isArabic ? _ar : _en;
    return table[key] ?? _en[key] ?? key;
  }

  String t(String key) => _get(key);

  /// Category names are stored bilingually in the database.
  String categoryName(String nameEn, String nameAr) =>
      isArabic ? (nameAr.isEmpty ? nameEn : nameAr) : nameEn;

  static const Map<String, String> _en = <String, String>{
    'appName': 'Mizan',
    'appTagline': 'Know where your money goes',
    'navHome': 'Home',
    'navActivity': 'Activity',
    'navBudgets': 'Budgets',
    'navInsights': 'Insights',
    'navSettings': 'Settings',
    'totalBalance': 'Total balance',
    'income': 'Income',
    'expense': 'Expenses',
    'thisMonth': 'This month',
    'spendingByCategory': 'Spending by category',
    'recentActivity': 'Recent activity',
    'seeAll': 'See all',
    'budget': 'Budget',
    'budgets': 'Budgets',
    'noBudgetYet': 'No budgets yet',
    'noBudgetHint': 'Set a monthly limit per category to stay on track.',
    'addBudget': 'Add budget',
    'monthlyLimit': 'Monthly limit',
    'spent': 'Spent',
    'remaining': 'Remaining',
    'overBudget': 'Over budget',
    'ofBudget': 'of',
    'noTransactions': 'No transactions yet',
    'noTransactionsHint': 'Tap the + button to record your first one.',
    'addTransaction': 'Add transaction',
    'editTransaction': 'Edit transaction',
    'amount': 'Amount',
    'category': 'Category',
    'note': 'Note',
    'noteHint': 'What was this for?',
    'date': 'Date',
    'account': 'Account',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'deleteTransaction': 'Delete transaction?',
    'deleteTransactionBody':
        'This action cannot be undone. The record will be removed permanently.',
    'confirm': 'Delete',
    'all': 'All',
    'search': 'Search notes and categories',
    'noResults': 'Nothing matches your search',
    'insights': 'Insights',
    'last6Months': 'Last 6 months',
    'incomeVsExpense': 'Income vs expenses',
    'topCategories': 'Top categories',
    'averageMonthlySpend': 'Average monthly spend',
    'savingsRate': 'Savings rate',
    'settings': 'Settings',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'themeSystem': 'System',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'language': 'Language',
    'currency': 'Currency',
    'data': 'Data',
    'resetDemoData': 'Reset demo data',
    'resetDemoDataBody':
        'This restores the sample transactions that ship with the app.',
    'reset': 'Reset',
    'about': 'About',
    'aboutBody':
        'Mizan is an offline-first finance tracker. Everything stays on your device — no account, no cloud, no tracking.',
    'version': 'Version',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'higherThanLastMonth': 'higher than last month',
    'lowerThanLastMonth': 'lower than last month',
    'onTrack': 'You are on track this month',
    'overspending': 'You are spending faster than last month',
    'add': 'Add',
    'requiredField': 'This field is required',
    'invalidAmount': 'Enter a valid amount greater than zero',
    'saved': 'Saved',
    'deleted': 'Transaction deleted',
    'demoDataRestored': 'Demo data restored',
    'expenseLower': 'expense',
    'incomeLower': 'income',
  };

  static const Map<String, String> _ar = <String, String>{
    'appName': 'ميزان',
    'appTagline': 'اعرف فلوسك رايحة فين',
    'navHome': 'الرئيسية',
    'navActivity': 'العمليات',
    'navBudgets': 'الميزانيات',
    'navInsights': 'التحليلات',
    'navSettings': 'الإعدادات',
    'totalBalance': 'الرصيد الإجمالي',
    'income': 'الدخل',
    'expense': 'المصروفات',
    'thisMonth': 'هذا الشهر',
    'spendingByCategory': 'المصروفات حسب الفئة',
    'recentActivity': 'أحدث العمليات',
    'seeAll': 'عرض الكل',
    'budget': 'ميزانية',
    'budgets': 'الميزانيات',
    'noBudgetYet': 'لا توجد ميزانيات بعد',
    'noBudgetHint': 'حدّد حدًا شهريًا لكل فئة للتحكم في مصروفاتك.',
    'addBudget': 'إضافة ميزانية',
    'monthlyLimit': 'الحد الشهري',
    'spent': 'المصروف',
    'remaining': 'المتبقي',
    'overBudget': 'تجاوزت الميزانية',
    'ofBudget': 'من',
    'noTransactions': 'لا توجد عمليات بعد',
    'noTransactionsHint': 'اضغط على زر + لتسجيل أول عملية.',
    'addTransaction': 'إضافة عملية',
    'editTransaction': 'تعديل العملية',
    'amount': 'المبلغ',
    'category': 'الفئة',
    'note': 'ملاحظة',
    'noteHint': 'المبلغ ده كان لماذا؟',
    'date': 'التاريخ',
    'account': 'الحساب',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'deleteTransaction': 'حذف العملية؟',
    'deleteTransactionBody':
        'لا يمكن التراجع عن هذه الخطوة. سيتم حذف العملية نهائيًا.',
    'confirm': 'حذف',
    'all': 'الكل',
    'search': 'ابحث في الملاحظات والفئات',
    'noResults': 'لا يوجد ما يطابق بحثك',
    'insights': 'التحليلات',
    'last6Months': 'آخر ٦ أشهر',
    'incomeVsExpense': 'الدخل مقابل المصروفات',
    'topCategories': 'أعلى الفئات',
    'averageMonthlySpend': 'متوسط المصروف الشهري',
    'savingsRate': 'معدل التوفير',
    'settings': 'الإعدادات',
    'appearance': 'المظهر',
    'theme': 'الثيم',
    'themeSystem': 'النظام',
    'themeLight': 'فاتح',
    'themeDark': 'داكن',
    'language': 'اللغة',
    'currency': 'العملة',
    'data': 'البيانات',
    'resetDemoData': 'إعادة ضبط البيانات التجريبية',
    'resetDemoDataBody':
        'سيتم استرجاع العمليات التجريبية المرفقة مع التطبيق.',
    'reset': 'إعادة ضبط',
    'about': 'عن التطبيق',
    'aboutBody':
        'ميزان تطبيق لإدارة المصروفات يعمل بدون إنترنت. كل بياناتك على جهازك فقط — بدون حساب، بدون سحابة، بدون تتبع.',
    'version': 'الإصدار',
    'today': 'اليوم',
    'yesterday': 'أمس',
    'higherThanLastMonth': 'أعلى من الشهر الماضي',
    'lowerThanLastMonth': 'أقل من الشهر الماضي',
    'onTrack': 'مصروفاتك تحت السيطرة هذا الشهر',
    'overspending': 'مصروفاتك أسرع من الشهر الماضي',
    'add': 'إضافة',
    'requiredField': 'هذا الحقل مطلوب',
    'invalidAmount': 'أدخل مبلغًا صحيحًا أكبر من صفر',
    'saved': 'تم الحفظ',
    'deleted': 'تم حذف العملية',
    'demoDataRestored': 'تم استرجاع البيانات التجريبية',
    'expenseLower': 'مصروف',
    'incomeLower': 'دخل',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
