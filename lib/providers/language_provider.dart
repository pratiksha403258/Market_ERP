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

  LanguageProvider() { _load(); }

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

  // ── Simple translation method ─────────────────────────────
  String t(String key) {
    if (_locale.languageCode == 'mr') {
      return _marathiTranslations[key] ?? key;
    }
    return _englishTranslations[key] ?? key;
  }

  // English translations (default)
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
    'banking_info_message': 'All banking fields are optional. You can add them later from the farmer profile.',
    
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


    // ignore: equal_keys_in_map
    'add_farmer': 'Add New Farmer',
  // ... existing translations ...
  // ignore: equal_keys_in_map
  'no_farmers_found': 'No farmers found',
  // ignore: equal_keys_in_map
  'add_first_farmer': 'Add Your First Farmer',
  
  // Add these new translations:
  'search_farmers': 'Search farmers...',
  'no_matching_farmers': 'No matching farmers found',
  'clear_search': 'Clear search',
  
  // Success/Error messages
  // ignore: equal_keys_in_map
  'success': 'Success',


  // Inside _englishTranslations map, after existing entries:
'ledger_title': 'Farmer Ledger',
'ledger_subtitle': 'Tap any farmer to view full ledger & download PDF',
'search_hint_ledger': 'Search by name or mobile...',
'due_short': 'Due',
'clear_short': 'Clear',
// ignore: equal_keys_in_map
'no_matching_farmers': 'No farmers match',
// ignore: equal_keys_in_map
'no_farmers_found': 'No farmers found',
'farmers': 'farmers',
'select_language_title': 'Select Language',
'select_language_message': 'Please choose language to view ledger',


'ledger_company': 'Farm ERP Market System',
'ledger_subtitle': 'Agricultural Market ERP System',
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
// Types
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


  };

  // Marathi translations
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
    'banking_info_message': 'सर्व बँकिंग फील्ड पर्यायी आहेत. तुम्ही ते नंतर शेतकरी प्रोफाइलमध्ये जोडू शकता.',
    
    // Steps
    'step': 'पायरी',
    'of': 'of',
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

      // Farmer Registration Screen
  // ignore: equal_keys_in_map
  'add_farmer': 'नवीन शेतकरी जोडा',
  // ... existing translations ...
  // ignore: equal_keys_in_map
  'no_farmers_found': 'कोणतेही शेतकरी सापडले नाहीत',
  // ignore: equal_keys_in_map
  'add_first_farmer': 'तुमचा पहिला शेतकरी जोडा',
  
  // Add these new translations:
  'search_farmers': 'शेतकरी शोधा...',
  'no_matching_farmers': 'जुळणारा कोणताही शेतकरी सापडला नाही',
  'clear_search': 'शोध साफ करा',
  
  // Success/Error messages
  // ignore: equal_keys_in_map
  'success': 'यश',

  // Inside _marathiTranslations map, after existing entries:
'ledger_title': 'शेतकरी खातेवही',
'ledger_subtitle': 'पूर्ण खातेवही पाहण्यासाठी आणि पीडीएफ डाउनलोड करण्यासाठी कोणत्याही शेतकऱ्यावर टॅप करा',
'search_hint_ledger': 'नाव किंवा मोबाइलने शोधा...',
'due_short': 'बाकी',
'clear_short': 'स्वच्छ',
// ignore: equal_keys_in_map
'no_matching_farmers': 'कोणताही शेतकरी जुळत नाही',
// ignore: equal_keys_in_map
'no_farmers_found': 'शेतकरी सापडले नाहीत',
'farmers': 'शेतकरी',
'select_language_title': 'भाषा निवडा',
'select_language_message': 'कृपया खातेवही पाहण्यासाठी भाषा निवडा',

'ledger_company': 'शेतकरी बाजार प्रणाली',
'ledger_subtitle': 'कृषी बाजार ERP प्रणाली',
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
// Types
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
  };
}