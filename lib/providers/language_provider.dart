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


    'add_farmer': 'Add New Farmer',
  // ... existing translations ...
  'no_farmers_found': 'No farmers found',
  'add_first_farmer': 'Add Your First Farmer',
  
  // Add these new translations:
  'search_farmers': 'Search farmers...',
  'no_matching_farmers': 'No matching farmers found',
  'clear_search': 'Clear search',
  
  // Success/Error messages
  'success': 'Success',
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
  'add_farmer': 'नवीन शेतकरी जोडा',
  // ... existing translations ...
  'no_farmers_found': 'कोणतेही शेतकरी सापडले नाहीत',
  'add_first_farmer': 'तुमचा पहिला शेतकरी जोडा',
  
  // Add these new translations:
  'search_farmers': 'शेतकरी शोधा...',
  'no_matching_farmers': 'जुळणारा कोणताही शेतकरी सापडला नाही',
  'clear_search': 'शोध साफ करा',
  
  // Success/Error messages
  'success': 'यश',
  };
}