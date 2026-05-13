// import 'package:agr_market/services/constant_service.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // ── Language data model ───────────────────────────────────────
// class AppLanguage {
//   final String code;
//   final String name;
//   final String nativeName;
//   final String flag;

//   const AppLanguage({
//     required this.code,
//     required this.name,
//     required this.nativeName,
//     required this.flag,
//   });
// }

// // ─────────────────────────────────────────────────────────────
// //  LANGUAGE PROVIDER
// // ─────────────────────────────────────────────────────────────
// class LanguageProvider extends ChangeNotifier {
//   Locale _locale = const Locale('en');
//   Locale get locale => _locale;

//   static const List<AppLanguage> supportedLanguages = [
//     AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
//     AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
//   ];

//   LanguageProvider() { _load(); }

//   Future<void> _load() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString(AppConstants.keyLanguage);
//     if (saved != null) {
//       _locale = Locale(saved);
//       notifyListeners();
//     }
//   }

//   Future<void> setLanguage(String code) async {
//     _locale = Locale(code);
//     notifyListeners();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(AppConstants.keyLanguage, code);
//   }

//   AppLanguage get currentLanguage =>
//       supportedLanguages.firstWhere((l) => l.code == _locale.languageCode,
//           orElse: () => supportedLanguages.first);

//   // ── Simple translation method ─────────────────────────────
//   String t(String key) {
//     if (_locale.languageCode == 'mr') {
//       return _marathiTranslations[key] ?? key;
//     }
//     return _englishTranslations[key] ?? key;
//   }

//   // English translations (default)
//   final Map<String, String> _englishTranslations = {
//     // Farmer Registration Screen
//     'add_farmer': 'Add New Farmer',
//     'farmer_saved': 'Farmer saved successfully!',
//     'farmer_name': 'Farmer Name',
//     'mobile': 'Mobile Number',
//     'village': 'Village',
//     'city': 'City',
//     'address': 'Address',
//     'save': 'Save',
//     'optional': 'Optional',
//     'required': 'is required',
//     'bank_account': 'Bank Account Number',
//     'ifsc': 'IFSC Code',
//     'bank_name': 'Bank Name',
//     'gst_number': 'GST Number',
    
//     // Common headers
//     'basic_information': 'Basic Information',
//     'address_details': 'Address Details',
//     'banking_details': 'Banking Details',
//     'farmer_name_contact': 'Farmer name and contact details',
//     'village_city_info': 'Village and city information',
//     'banking_optional': 'Optional — for direct transfers',
//     'banking_info_message': 'All banking fields are optional. You can add them later from the farmer profile.',
    
//     // Steps
//     'step': 'Step',
//     'of': 'of',
//     'continue': 'Continue',
    
//     // Dashboard / Common
//     'dashboard': 'Dashboard',
//     'total_farmers': 'Total Farmers',
//     'total_purchases': 'Total Purchases',
//     'pending_dues': 'Pending Dues',
//     'advance_balance': 'Advance Balance',
//     'view_all': 'View All',
//     'recent_farmers': 'Recent Farmers',
//     'search': 'Search',
//     'filter': 'Filter',
//     'no_data': 'No data found',
    
//     // Farmer List
//     'farmers_list': 'Farmers List',
//     'total': 'Total',
//     'active': 'Active',
//     'inactive': 'Inactive',
//     'edit': 'Edit',
//     'delete': 'Delete',
//     'delete_farmer': 'Delete Farmer',
//     'delete_confirmation': 'Are you sure you want to delete',
//     'cancel': 'Cancel',
//     'farmer_deleted': 'Farmer deleted successfully',
//     'retry': 'Retry',
//     'no_farmers_found': 'No farmers found',
//     'add_first_farmer': 'Add Your First Farmer',
    
//     // Success/Error messages
//     'success': 'Success',
//     'error': 'Error',
//     'loading': 'Loading...',
//     'network_error': 'Network error. Please try again.',
    
//     // Form validations
//     'name_too_short': 'Name too short',
//     'enter_valid_mobile': 'Enter valid 10-digit number',
//     'field_required': 'This field is required',


//     // ignore: equal_keys_in_map
//     'add_farmer': 'Add New Farmer',
//   // ... existing translations ...
//   // ignore: equal_keys_in_map
//   'no_farmers_found': 'No farmers found',
//   // ignore: equal_keys_in_map
//   'add_first_farmer': 'Add Your First Farmer',
  
//   // Add these new translations:
//   'search_farmers': 'Search farmers...',
//   'no_matching_farmers': 'No matching farmers found',
//   'clear_search': 'Clear search',
  
//   // Success/Error messages
//   // ignore: equal_keys_in_map
//   'success': 'Success',


//   // Inside _englishTranslations map, after existing entries:
// 'ledger_title': 'Farmer Ledger',
// 'ledger_subtitle': 'Tap any farmer to view full ledger & download PDF',
// 'search_hint_ledger': 'Search by name or mobile...',
// 'due_short': 'Due',
// 'clear_short': 'Clear',
// // ignore: equal_keys_in_map
// 'no_matching_farmers': 'No farmers match',
// // ignore: equal_keys_in_map
// 'no_farmers_found': 'No farmers found',
// 'farmers': 'farmers',
// 'select_language_title': 'Select Language',
// 'select_language_message': 'Please choose language to view ledger',


// 'ledger_company': 'Farm ERP Market System',
// 'ledger_subtitle': 'Agricultural Market ERP System',
// 'ledger_farmer_name': 'Farmer Name:',
// 'ledger_ledger_date': 'Ledger Date:',
// 'ledger_mobile': 'Mobile:',
// 'ledger_period': 'Period:',
// 'ledger_all_tx': 'All Transactions',
// 'ledger_trans_history': 'Transaction History',
// 'ledger_col_date': 'Date',
// 'ledger_col_desc': 'Description',
// 'ledger_col_ref': 'Reference No',
// 'ledger_col_credit': 'Credit (Rs.)',
// 'ledger_col_debit': 'Debit (Rs.)',
// 'ledger_col_balance': 'Balance (Rs.)',
// 'ledger_total': 'Total',
// 'ledger_on_account': 'On Account Balance',
// 'ledger_final_balance': 'Final Balance',
// 'ledger_for_label': 'For,',
// 'ledger_authorised': 'Authorised Signatory',
// 'ledger_page': 'Page',
// 'ledger_of': 'of',
// // Types
// 'type_purchase': 'Purchase',
// 'type_payment': 'Payment',
// 'type_advance': 'Advance',
// 'type_reversal': 'Reversal',
// // UI chips
// 'total_paid': 'Total Paid',
// 'total_purchased': 'Purchased',
// 'due': 'Due',
// 'cleared': 'Cleared',
// 'balance': 'Bal',


// // In your translation files, add:
// 'farmers_tab': 'Farmers',
// 'operators_tab': 'Operators',
// 'search_hint_farmer_ledger': 'Search farmers by name or mobile...',
// 'search_hint_operator_ledger': 'Search operators by name or email...',
// 'no_matching_operators': 'No matching operators found for',
// 'no_operators_found': 'No operators found',
// 'operator_name': 'Operator Name',
// 'net_profit_short': 'Net Profit',
// 'email': 'Email',
// 'total_sales': 'Total Sales',
// 'total_expenses': 'Total Expenses',
// 'net_profit': 'Net Profit',


//   };

//   // Marathi translations
//   final Map<String, String> _marathiTranslations = {
//     // Farmer Registration Screen
//     'add_farmer': 'नवीन शेतकरी जोडा',
//     'farmer_saved': 'शेतकरी यशस्वीरित्या जतन केला!',
//     'farmer_name': 'शेतकऱ्याचे नाव',
//     'mobile': 'मोबाइल क्रमांक',
//     'village': 'गाव',
//     'city': 'शहर',
//     'address': 'पत्ता',
//     'save': 'जतन करा',
//     'optional': 'पर्यायी',
//     'required': 'आवश्यक आहे',
//     'bank_account': 'बँक खाते क्रमांक',
//     'ifsc': 'आयएफएससी कोड',
//     'bank_name': 'बँकेचे नाव',
//     'gst_number': 'जीएसटी क्रमांक',
    
//     // Common headers
//     'basic_information': 'मूलभूत माहिती',
//     'address_details': 'पत्त्याची माहिती',
//     'banking_details': 'बँकिंग तपशील',
//     'farmer_name_contact': 'शेतकऱ्याचे नाव आणि संपर्क तपशील',
//     'village_city_info': 'गाव आणि शहराची माहिती',
//     'banking_optional': 'पर्यायी — थेट हस्तांतरणासाठी',
//     'banking_info_message': 'सर्व बँकिंग फील्ड पर्यायी आहेत. तुम्ही ते नंतर शेतकरी प्रोफाइलमध्ये जोडू शकता.',
    
//     // Steps
//     'step': 'पायरी',
//     'of': 'of',
//     'continue': 'पुढे जा',
    
//     // Dashboard / Common
//     'dashboard': 'डॅशबोर्ड',
//     'total_farmers': 'एकूण शेतकरी',
//     'total_purchases': 'एकूण खरेदी',
//     'pending_dues': 'बाकी देयके',
//     'advance_balance': 'अग्रिम शिल्लक',
//     'view_all': 'सर्व पहा',
//     'recent_farmers': 'अलीकडील शेतकरी',
//     'search': 'शोधा',
//     'filter': 'फिल्टर',
//     'no_data': 'डेटा सापडला नाही',
    
//     // Farmer List
//     'farmers_list': 'शेतकऱ्यांची यादी',
//     'total': 'एकूण',
//     'active': 'सक्रिय',
//     'inactive': 'निष्क्रिय',
//     'edit': 'संपादित करा',
//     'delete': 'हटवा',
//     'delete_farmer': 'शेतकरी हटवा',
//     'delete_confirmation': 'तुम्हाला खात्री आहे की तुम्ही हटवू इच्छिता',
//     'cancel': 'रद्द करा',
//     'farmer_deleted': 'शेतकरी यशस्वीरित्या हटवला',
//     'retry': 'पुन्हा प्रयत्न करा',
//     'no_farmers_found': 'कोणतेही शेतकरी सापडले नाहीत',
//     'add_first_farmer': 'तुमचा पहिला शेतकरी जोडा',
    
//     // Success/Error messages
//     'success': 'यश',
//     'error': 'त्रुटी',
//     'loading': 'लोड करत आहे...',
//     'network_error': 'नेटवर्क त्रुटी. कृपया पुन्हा प्रयत्न करा.',
    
//     // Form validations
//     'name_too_short': 'नाव खूप लहान आहे',
//     'enter_valid_mobile': 'वैध 10-अंकी क्रमांक प्रविष्ट करा',
//     'field_required': 'हे फील्ड आवश्यक आहे',

//       // Farmer Registration Screen
//   // ignore: equal_keys_in_map
//   'add_farmer': 'नवीन शेतकरी जोडा',
//   // ... existing translations ...
//   // ignore: equal_keys_in_map
//   'no_farmers_found': 'कोणतेही शेतकरी सापडले नाहीत',
//   // ignore: equal_keys_in_map
//   'add_first_farmer': 'तुमचा पहिला शेतकरी जोडा',
  
//   // Add these new translations:
//   'search_farmers': 'शेतकरी शोधा...',
//   'no_matching_farmers': 'जुळणारा कोणताही शेतकरी सापडला नाही',
//   'clear_search': 'शोध साफ करा',
  
//   // Success/Error messages
//   // ignore: equal_keys_in_map
//   'success': 'यश',

//   // Inside _marathiTranslations map, after existing entries:
// 'ledger_title': 'शेतकरी खातेवही',
// 'ledger_subtitle': 'पूर्ण खातेवही पाहण्यासाठी आणि पीडीएफ डाउनलोड करण्यासाठी कोणत्याही शेतकऱ्यावर टॅप करा',
// 'search_hint_ledger': 'नाव किंवा मोबाइलने शोधा...',
// 'due_short': 'बाकी',
// 'clear_short': 'स्वच्छ',
// // ignore: equal_keys_in_map
// 'no_matching_farmers': 'कोणताही शेतकरी जुळत नाही',
// // ignore: equal_keys_in_map
// 'no_farmers_found': 'शेतकरी सापडले नाहीत',
// 'farmers': 'शेतकरी',
// 'select_language_title': 'भाषा निवडा',
// 'select_language_message': 'कृपया खातेवही पाहण्यासाठी भाषा निवडा',

// 'ledger_company': 'शेतकरी बाजार प्रणाली',
// 'ledger_subtitle': 'कृषी बाजार ERP प्रणाली',
// 'ledger_farmer_name': 'शेतकऱ्याचे नाव:',
// 'ledger_ledger_date': 'खाते दिनांक:',
// 'ledger_mobile': 'मोबाइल:',
// 'ledger_period': 'कालावधी:',
// 'ledger_all_tx': 'सर्व व्यवहार',
// 'ledger_trans_history': 'व्यवहाराचा इतिहास',
// 'ledger_col_date': 'दिनांक',
// 'ledger_col_desc': 'वर्णन',
// 'ledger_col_ref': 'संदर्भ क्र.',
// 'ledger_col_credit': 'जमा (Rs.)',
// 'ledger_col_debit': 'नावे (Rs.)',
// 'ledger_col_balance': 'शिल्लक (Rs.)',
// 'ledger_total': 'एकूण',
// 'ledger_on_account': 'खाते शिल्लक',
// 'ledger_final_balance': 'अंतिम शिल्लक',
// 'ledger_for_label': 'साठी,',
// 'ledger_authorised': 'अधिकृत स्वाक्षरी',
// 'ledger_page': 'पृष्ठ',
// 'ledger_of': 'पैकी',
// // Types
// 'type_purchase': 'खरेदी',
// 'type_payment': 'पेमेंट',
// 'type_advance': 'अग्रिम',
// 'type_reversal': 'उलट',
// // UI chips
// 'total_paid': 'एकूण दिले',
// 'total_purchased': 'एकूण खरेदी',
// 'due': 'बाकी',
// 'cleared': 'स्वच्छ',
// 'balance': 'शिल्लक',
//   };
// }


import 'package:agr_market/services/constant_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Language data model ───────────────────────────────────────
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

// ─────────────────────────────────────────────────────────────
//  LANGUAGE PROVIDER
// ─────────────────────────────────────────────────────────────
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
  ];

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyLanguage);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, code);
  }

  AppLanguage get currentLanguage =>
      supportedLanguages.firstWhere((l) => l.code == _locale.languageCode,
          orElse: () => supportedLanguages.first);

  bool get isMarathi => _locale.languageCode == 'mr';

  // ── Simple translation method ─────────────────────────────
  String t(String key) {
    if (_locale.languageCode == 'mr') {
      return _marathiTranslations[key] ?? _englishTranslations[key] ?? key;
    }
    return _englishTranslations[key] ?? key;
  }

  // ─────────────────────────────────────────────────────────
  //  ENGLISH TRANSLATIONS
  // ─────────────────────────────────────────────────────────
  final Map<String, String> _englishTranslations = {
    // Farmer Registration Screen
    'add_farmer': 'Add New Farmer',
    'farmer_saved': 'Farmer saved successfully!',
    'farmer_name': 'Farmer Name',
    'mobile': 'Mobile Number',
    'village': 'Village',
    'city': 'City',
    'address': 'Address',
    'save': 'Save',
    'optional': 'Optional',
    'required': 'is required',
    'bank_account': 'Bank Account Number',
    'ifsc': 'IFSC Code',
    'bank_name': 'Bank Name',
    'gst_number': 'GST Number',

    // Common headers
    'basic_information': 'Basic Information',
    'address_details': 'Address Details',
    'banking_details': 'Banking Details',
    'farmer_name_contact': 'Farmer name and contact details',
    'village_city_info': 'Village and city information',
    'banking_optional': 'Optional — for direct transfers',
    'banking_info_message':
        'All banking fields are optional. You can add them later from the farmer profile.',

    // Steps
    'step': 'Step',
    'of': 'of',
    'continue': 'Continue',

    // Dashboard / Common
    'dashboard': 'Dashboard',
    'total_farmers': 'Total Farmers',
    'total_purchases': 'Total Purchases',
    'pending_dues': 'Pending Dues',
    'advance_balance': 'Advance Balance',
    'view_all': 'View All',
    'recent_farmers': 'Recent Farmers',
    'search': 'Search',
    'filter': 'Filter',
    'no_data': 'No data found',

    // Farmer List
    'farmers_list': 'Farmers List',
    'total': 'Total',
    'active': 'Active',
    'inactive': 'Inactive',
    'edit': 'Edit',
    'delete': 'Delete',
    'delete_farmer': 'Delete Farmer',
    'delete_confirmation': 'Are you sure you want to delete',
    'cancel': 'Cancel',
    'farmer_deleted': 'Farmer deleted successfully',
    'retry': 'Retry',
    'no_farmers_found': 'No farmers found',
    'add_first_farmer': 'Add Your First Farmer',

    // Success/Error messages
    'success': 'Success',
    'error': 'Error',
    'loading': 'Loading...',
    'network_error': 'Network error. Please try again.',

    // Form validations
    'name_too_short': 'Name too short',
    'enter_valid_mobile': 'Enter valid 10-digit number',
    'field_required': 'This field is required',

    // Search
    'search_farmers': 'Search farmers...',
    'no_matching_farmers': 'No matching farmers found',
    'clear_search': 'Clear search',

    // Ledger
    'ledger_title': 'Farmer Ledger',
    'ledger_subtitle': 'Tap any farmer to view full ledger & download PDF',
    'search_hint_ledger': 'Search by name or mobile...',
    'due_short': 'Due',
    'clear_short': 'Clear',
    'farmers': 'farmers',
    'select_language_title': 'Select Language',
    'select_language_message': 'Please choose language to view ledger',
    'ledger_company': 'Farm ERP Market System',
    'ledger_farmer_name': 'Farmer Name:',
    'ledger_ledger_date': 'Ledger Date:',
    'ledger_mobile': 'Mobile:',
    'ledger_period': 'Period:',
    'ledger_all_tx': 'All Transactions',
    'ledger_trans_history': 'Transaction History',
    'ledger_col_date': 'Date',
    'ledger_col_desc': 'Description',
    'ledger_col_ref': 'Reference No',
    'ledger_col_credit': 'Credit (Rs.)',
    'ledger_col_debit': 'Debit (Rs.)',
    'ledger_col_balance': 'Balance (Rs.)',
    'ledger_total': 'Total',
    'ledger_on_account': 'On Account Balance',
    'ledger_final_balance': 'Final Balance',
    'ledger_for_label': 'For,',
    'ledger_authorised': 'Authorised Signatory',
    'ledger_page': 'Page',
    'ledger_of': 'of',

    // Transaction types
    'type_purchase': 'Purchase',
    'type_payment': 'Payment',
    'type_advance': 'Advance',
    'type_reversal': 'Reversal',

    // UI chips
    'total_paid': 'Total Paid',
    'total_purchased': 'Purchased',
    'due': 'Due',
    'cleared': 'Cleared',
    'balance': 'Bal',

    // Tabs
    'farmers_tab': 'Farmers',
    'operators_tab': 'Operators',
    'search_hint_farmer_ledger': 'Search farmers by name or mobile...',
    'search_hint_operator_ledger': 'Search operators by name or email...',
    'no_matching_operators': 'No matching operators found for',
    'no_operators_found': 'No operators found',
    'operator_name': 'Operator Name',
    'net_profit_short': 'Net Profit',
    'email': 'Email',
    'total_sales': 'Total Sales',
    'total_expenses': 'Total Expenses',
    'net_profit': 'Net Profit',

    // ─────────────────────────────────────────────────────
    //  SALE DETAIL SCREEN
    // ─────────────────────────────────────────────────────
    'sale_detail_title': 'Sale Details',
    'invoice_label': 'INVOICE',
    'date_label': 'Date',
    'grand_total_label': 'Grand Total',
    'generate_invoice_btn': 'Generate Invoice',

    // Sections
    'buyer_details': 'Buyer Details',
    'products_section': 'Products',
    'payment_summary': 'Payment Summary',
    'notes_section': 'Notes',

    // Buyer info rows
    'name_label': 'Name',
    'mobile_label': 'Mobile',
    'gst_label': 'GST',

    // Product table headers
    'col_product': 'Product',
    'col_qty': 'Qty',
    'col_rate': 'Rate',
    'col_total': 'Total',

    // Payment summary rows
    'sub_total_label': 'Sub Total',
    'grand_total_row': 'Grand Total',
    'payment_mode_label': 'Payment Mode',
    'ref_label': 'Ref',

    // ─────────────────────────────────────────────────────
    //  SALES INVOICE SCREEN (on-screen card)
    // ─────────────────────────────────────────────────────
    'invoice_screen_title': 'Sales Invoice',
    'tax_invoice_badge': 'TAX INVOICE',
    'company_name': 'Jai Shivrai Vegetable Co.',
    'company_address': 'Vesarane, Tal. Kalwan, Dist. Nashik',
    'company_prop': 'Prop. Rakesh Hire | Mob: 9021699991 / 9623956396',
    'invoice_no_label': 'Invoice No.:',
    'date_label_inv': 'Date:',

    // Buyer section
    'buyer_section_label': 'खरेदीदार / Buyer',
    'mobile_prefix': 'Mobile:',
    'gst_prefix': 'GST:',
    'address_prefix': 'Address:',

    // Product table (bilingual in invoice kept as-is per sample)
    'col_product_inv': 'उत्पादन / Product',
    'col_warehouse_inv': 'गोदाम / Warehouse',
    'col_qty_inv': 'प्रमाण / Qty',
    'col_rate_inv': 'दर / Rate (₹)',
    'col_amount_inv': 'रक्कम / Amount (₹)',

    // Totals
    'sub_total_inv': 'उप-एकूण / Sub Total',
    'grand_total_inv': 'एकूण रक्कम / Grand Total',
    'amount_words_prefix': 'रक्कम अक्षरी :',

    // Payment
    'payment_mode_inv': 'पेमेंट पद्धत / Payment Mode:',
    'ref_no_inv': 'संदर्भ क्रमांक / Ref. No.:',

    // Notes
    'notes_inv': 'सूचना / Notes:',

    // Footer
    'buyers_signature': "Buyer's Signature",
    'for_company': 'For Jai Shivrai Vegetable Co.',
    'auth_signatory': 'Authorised Signatory',
    'footer_company': 'जय शिवराय कैलिटेबल, कळवण',
    'generated_on': 'Generated on:',

    // ─────────────────────────────────────────────────────
    //  PDF labels (bilingual kept in sample style)
    // ─────────────────────────────────────────────────────
    'pdf_buyer_label': 'खरेदीदार / Buyer',
    'pdf_sub_total': 'उप-एकूण / Sub Total',
    'pdf_grand_total': 'एकूण रक्कम / Grand Total',
    'pdf_amount_words': 'रक्कम अक्षरी :',
    'pdf_payment_mode': 'पेमेंट पद्धत / Payment Mode:',
    'pdf_ref_no': 'संदर्भ क्रमांक / Ref. No.:',
    'pdf_notes': 'सूचना / Notes:',
    'pdf_buyers_sig': "Buyer's Signature",
    'pdf_for_company': 'For Jai Shivrai Vegetable Co.',
    'pdf_auth_sig': 'Authorised Signatory',
    'pdf_footer': 'जय शिवराय कैलिटेबल, कळवण',
    'pdf_generated': 'Generated on:',
    'pdf_col_product': 'उत्पादन / Product',
    'pdf_col_warehouse': 'गोदाम / Warehouse',
    'pdf_col_qty': 'प्रमाण / Qty',
    'pdf_col_rate': 'दर / Rate (₹)',
    'pdf_col_amount': 'रक्कम / Amount (₹)',
  };

  // ─────────────────────────────────────────────────────────
  //  MARATHI TRANSLATIONS
  // ─────────────────────────────────────────────────────────
  final Map<String, String> _marathiTranslations = {
    // Farmer Registration Screen
    'add_farmer': 'नवीन शेतकरी जोडा',
    'farmer_saved': 'शेतकरी यशस्वीरित्या जतन केला!',
    'farmer_name': 'शेतकऱ्याचे नाव',
    'mobile': 'मोबाइल क्रमांक',
    'village': 'गाव',
    'city': 'शहर',
    'address': 'पत्ता',
    'save': 'जतन करा',
    'optional': 'पर्यायी',
    'required': 'आवश्यक आहे',
    'bank_account': 'बँक खाते क्रमांक',
    'ifsc': 'आयएफएससी कोड',
    'bank_name': 'बँकेचे नाव',
    'gst_number': 'जीएसटी क्रमांक',

    // Common headers
    'basic_information': 'मूलभूत माहिती',
    'address_details': 'पत्त्याची माहिती',
    'banking_details': 'बँकिंग तपशील',
    'farmer_name_contact': 'शेतकऱ्याचे नाव आणि संपर्क तपशील',
    'village_city_info': 'गाव आणि शहराची माहिती',
    'banking_optional': 'पर्यायी — थेट हस्तांतरणासाठी',
    'banking_info_message':
        'सर्व बँकिंग फील्ड पर्यायी आहेत. तुम्ही ते नंतर शेतकरी प्रोफाइलमध्ये जोडू शकता.',

    // Steps
    'step': 'पायरी',
    'of': 'पैकी',
    'continue': 'पुढे जा',

    // Dashboard / Common
    'dashboard': 'डॅशबोर्ड',
    'total_farmers': 'एकूण शेतकरी',
    'total_purchases': 'एकूण खरेदी',
    'pending_dues': 'बाकी देयके',
    'advance_balance': 'अग्रिम शिल्लक',
    'view_all': 'सर्व पहा',
    'recent_farmers': 'अलीकडील शेतकरी',
    'search': 'शोधा',
    'filter': 'फिल्टर',
    'no_data': 'डेटा सापडला नाही',

    // Farmer List
    'farmers_list': 'शेतकऱ्यांची यादी',
    'total': 'एकूण',
    'active': 'सक्रिय',
    'inactive': 'निष्क्रिय',
    'edit': 'संपादित करा',
    'delete': 'हटवा',
    'delete_farmer': 'शेतकरी हटवा',
    'delete_confirmation': 'तुम्हाला खात्री आहे की तुम्ही हटवू इच्छिता',
    'cancel': 'रद्द करा',
    'farmer_deleted': 'शेतकरी यशस्वीरित्या हटवला',
    'retry': 'पुन्हा प्रयत्न करा',
    'no_farmers_found': 'कोणतेही शेतकरी सापडले नाहीत',
    'add_first_farmer': 'तुमचा पहिला शेतकरी जोडा',

    // Success/Error messages
    'success': 'यश',
    'error': 'त्रुटी',
    'loading': 'लोड करत आहे...',
    'network_error': 'नेटवर्क त्रुटी. कृपया पुन्हा प्रयत्न करा.',

    // Form validations
    'name_too_short': 'नाव खूप लहान आहे',
    'enter_valid_mobile': 'वैध 10-अंकी क्रमांक प्रविष्ट करा',
    'field_required': 'हे फील्ड आवश्यक आहे',

    // Search
    'search_farmers': 'शेतकरी शोधा...',
    'no_matching_farmers': 'जुळणारा कोणताही शेतकरी सापडला नाही',
    'clear_search': 'शोध साफ करा',

    // Ledger
    'ledger_title': 'शेतकरी खातेवही',
    'ledger_subtitle': 'पूर्ण खातेवही पाहण्यासाठी आणि पीडीएफ डाउनलोड करण्यासाठी टॅप करा',
    'search_hint_ledger': 'नाव किंवा मोबाइलने शोधा...',
    'due_short': 'बाकी',
    'clear_short': 'स्वच्छ',
    'farmers': 'शेतकरी',
    'select_language_title': 'भाषा निवडा',
    'select_language_message': 'कृपया खातेवही पाहण्यासाठी भाषा निवडा',
    'ledger_company': 'शेतकरी बाजार प्रणाली',
    'ledger_farmer_name': 'शेतकऱ्याचे नाव:',
    'ledger_ledger_date': 'खाते दिनांक:',
    'ledger_mobile': 'मोबाइल:',
    'ledger_period': 'कालावधी:',
    'ledger_all_tx': 'सर्व व्यवहार',
    'ledger_trans_history': 'व्यवहाराचा इतिहास',
    'ledger_col_date': 'दिनांक',
    'ledger_col_desc': 'वर्णन',
    'ledger_col_ref': 'संदर्भ क्र.',
    'ledger_col_credit': 'जमा (Rs.)',
    'ledger_col_debit': 'नावे (Rs.)',
    'ledger_col_balance': 'शिल्लक (Rs.)',
    'ledger_total': 'एकूण',
    'ledger_on_account': 'खाते शिल्लक',
    'ledger_final_balance': 'अंतिम शिल्लक',
    'ledger_for_label': 'साठी,',
    'ledger_authorised': 'अधिकृत स्वाक्षरी',
    'ledger_page': 'पृष्ठ',
    'ledger_of': 'पैकी',

    // Transaction types
    'type_purchase': 'खरेदी',
    'type_payment': 'पेमेंट',
    'type_advance': 'अग्रिम',
    'type_reversal': 'उलट',

    // UI chips
    'total_paid': 'एकूण दिले',
    'total_purchased': 'एकूण खरेदी',
    'due': 'बाकी',
    'cleared': 'स्वच्छ',
    'balance': 'शिल्लक',

    // Tabs
    'farmers_tab': 'शेतकरी',
    'operators_tab': 'ऑपरेटर',
    'search_hint_farmer_ledger': 'नाव किंवा मोबाइलने शोधा...',
    'search_hint_operator_ledger': 'नाव किंवा ईमेलने शोधा...',
    'no_matching_operators': 'जुळणारा कोणताही ऑपरेटर सापडला नाही',
    'no_operators_found': 'ऑपरेटर सापडले नाहीत',
    'operator_name': 'ऑपरेटरचे नाव',
    'net_profit_short': 'निव्वळ नफा',
    'email': 'ईमेल',
    'total_sales': 'एकूण विक्री',
    'total_expenses': 'एकूण खर्च',
    'net_profit': 'निव्वळ नफा',

    // ─────────────────────────────────────────────────────
    //  SALE DETAIL SCREEN
    // ─────────────────────────────────────────────────────
    'sale_detail_title': 'विक्री तपशील',
    'invoice_label': 'बीजक',
    'date_label': 'दिनांक',
    'grand_total_label': 'एकूण रक्कम',
    'generate_invoice_btn': 'बीजक तयार करा',

    // Sections
    'buyer_details': 'खरेदीदार माहिती',
    'products_section': 'उत्पादने',
    'payment_summary': 'पेमेंट सारांश',
    'notes_section': 'टिपा',

    // Buyer info rows
    'name_label': 'नाव',
    'mobile_label': 'मोबाइल',
    'gst_label': 'जीएसटी',

    // Product table headers
    'col_product': 'उत्पादन',
    'col_qty': 'प्रमाण',
    'col_rate': 'दर',
    'col_total': 'एकूण',

    // Payment summary rows
    'sub_total_label': 'उप-एकूण',
    'grand_total_row': 'एकूण रक्कम',
    'payment_mode_label': 'पेमेंट पद्धत',
    'ref_label': 'संदर्भ',

    // ─────────────────────────────────────────────────────
    //  SALES INVOICE SCREEN (on-screen card)
    // ─────────────────────────────────────────────────────
    'invoice_screen_title': 'विक्री बीजक',
    'tax_invoice_badge': 'कर बीजक',
    'company_name': 'जय शिवराय भाजीपाला',
    'company_address': 'वेसराणे, ता. कळवण, जि. नाशिक',
    'company_prop': 'प्रो. राकेश हिरे | मोबा: 9021699991 / 9623956396',
    'invoice_no_label': 'बीजक क्र.:',
    'date_label_inv': 'दिनांक:',

    // Buyer section
    'buyer_section_label': 'खरेदीदार / Buyer',
    'mobile_prefix': 'मोबाइल:',
    'gst_prefix': 'जीएसटी:',
    'address_prefix': 'पत्ता:',

    // Product table (bilingual labels kept per sample invoice design)
    'col_product_inv': 'उत्पादन / Product',
    'col_warehouse_inv': 'गोदाम / Warehouse',
    'col_qty_inv': 'प्रमाण / Qty',
    'col_rate_inv': 'दर / Rate (₹)',
    'col_amount_inv': 'रक्कम / Amount (₹)',

    // Totals
    'sub_total_inv': 'उप-एकूण / Sub Total',
    'grand_total_inv': 'एकूण रक्कम / Grand Total',
    'amount_words_prefix': 'रक्कम अक्षरी :',

    // Payment
    'payment_mode_inv': 'पेमेंट पद्धत / Payment Mode:',
    'ref_no_inv': 'संदर्भ क्रमांक / Ref. No.:',

    // Notes
    'notes_inv': 'सूचना / Notes:',

    // Footer
    'buyers_signature': 'खरेदीदाराची स्वाक्षरी',
    'for_company': 'जय शिवराय भाजीपाला साठी',
    'auth_signatory': 'अधिकृत स्वाक्षरी',
    'footer_company': 'जय शिवराय कैलिटेबल, कळवण',
    'generated_on': 'तयार केले:',

    // PDF labels
    'pdf_buyer_label': 'खरेदीदार / Buyer',
    'pdf_sub_total': 'उप-एकूण / Sub Total',
    'pdf_grand_total': 'एकूण रक्कम / Grand Total',
    'pdf_amount_words': 'रक्कम अक्षरी :',
    'pdf_payment_mode': 'पेमेंट पद्धत / Payment Mode:',
    'pdf_ref_no': 'संदर्भ क्रमांक / Ref. No.:',
    'pdf_notes': 'सूचना / Notes:',
    'pdf_buyers_sig': 'खरेदीदाराची स्वाक्षरी',
    'pdf_for_company': 'जय शिवराय भाजीपाला साठी',
    'pdf_auth_sig': 'अधिकृत स्वाक्षरी',
    'pdf_footer': 'जय शिवराय कैलिटेबल, कळवण',
    'pdf_generated': 'तयार केले:',
    'pdf_col_product': 'उत्पादन / Product',
    'pdf_col_warehouse': 'गोदाम / Warehouse',
    'pdf_col_qty': 'प्रमाण / Qty',
    'pdf_col_rate': 'दर / Rate (₹)',
    'pdf_col_amount': 'रक्कम / Amount (₹)',
  };
}