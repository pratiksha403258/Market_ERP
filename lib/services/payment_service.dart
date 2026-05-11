// import 'package:dio/dio.dart';
// import '../models/payment_model.dart';
// import 'dio_client.dart';
// import 'constant_service.dart';

// class PaymentService {
//   static final PaymentService _instance = PaymentService._internal();
//   factory PaymentService() => _instance;
//   PaymentService._internal();

//   final Dio _dio = DioClient.instance.dio;

//   /// POST /api/payments - Record a new payment
//   Future<PaymentModel> recordPayment(PaymentRequest request) async {
//     try {
//       final response = await _dio.post(
//        ApiRoutes.payments,
//         data: request.toJson(),
//       );

//       final data = response.data as Map<String, dynamic>;
      
//       if (data['success'] == true) {
//         return PaymentModel.fromJson(data['data'] ?? data);
//       } else {
//         throw Exception(data['message'] ?? 'Failed to record payment');
//       }
//     } on DioException catch (e) {
//       throw _handleError(e);
//     }
//   }

//   /// GET /api/payments - List payments with filters
//   Future<List<PaymentModel>> getPayments({
//     String? purchaseId,
//     String? farmerId,
//     int? page,
//     int? limit,
//   }) async {
//     try {
//       final queryParams = <String, dynamic>{};
//       if (purchaseId != null) queryParams['purchaseId'] = purchaseId;
//       if (farmerId != null) queryParams['farmerId'] = farmerId;
//       if (page != null) queryParams['page'] = page;
//       if (limit != null) queryParams['limit'] = limit;

//       final response = await _dio.get(
//        ApiRoutes.payments,
//         queryParameters: queryParams,
//       );

//       final data = response.data as Map<String, dynamic>;
      
//       if (data['success'] == true) {
//         final paymentsList = data['data'] as List? ?? [];
//         return paymentsList
//             .map((item) => PaymentModel.fromJson(item))
//             .toList();
//       } else {
//         return [];
//       }
//     } on DioException catch (e) {
//       throw _handleError(e);
//     }
//   }

//   /// GET /api/payments/:id - Get payment details
//   Future<PaymentModel?> getPaymentById(String paymentId) async {
//     try {
//       final response = await _dio.get(
//         ApiRoutes.paymentById(paymentId),
//         );
//       final data = response.data as Map<String, dynamic>;
      
//       if (data['success'] == true) {
//         return PaymentModel.fromJson(data['data'] ?? data);
//       }
//       return null;
//     } on DioException catch (e) {
//       throw _handleError(e);
//     }
//   }

//   /// GET /api/payments/due-summary - Get all pending dues
//   Future<List<DueSummary>> getDueSummary() async {
//     try {
//       final response = await _dio.get(
//         ApiRoutes.paymentDueSummary,
//         );
//       final data = response.data as Map<String, dynamic>;
      
//       if (data['success'] == true) {
//         final dueList = data['data'] as List? ?? [];
//         return dueList
//             .map((item) => DueSummary.fromJson(item))
//             .toList();
//       }
//       return [];
//     } on DioException catch (e) {
//       throw _handleError(e);
//     }
//   }

//   String _handleError(DioException e) {
//     if (e.response != null) {
//       final data = e.response?.data as Map<String, dynamic>?;
//       final message = data?['message'] ?? data?['error'] ?? 'Something went wrong';
//       return message;
//     } else if (e.type == DioExceptionType.connectionTimeout ||
//                e.type == DioExceptionType.receiveTimeout) {
//       return 'Connection timeout. Please try again.';
//     } else if (e.type == DioExceptionType.connectionError) {
//       return 'No internet connection.';
//     }
//     return e.message ?? 'Failed to process payment';
//   }
// }

// class DueSummary {
//   final String purchaseId;
//   final String receiptNumber;
//   final String farmerId;
//   final String farmerName;
//   final String? farmerMobile;
//   final double finalPayable;
//   final double amountPaid;
//   final double amountDue;
//   final DateTime purchaseDate;

//   DueSummary({
//     required this.purchaseId,
//     required this.receiptNumber,
//     required this.farmerId,
//     required this.farmerName,
//     this.farmerMobile,
//     required this.finalPayable,
//     required this.amountPaid,
//     required this.amountDue,
//     required this.purchaseDate,
//   });

//   factory DueSummary.fromJson(Map<String, dynamic> json) {
//     return DueSummary(
//       purchaseId: json['purchaseId']?.toString() ?? json['purchase_id']?.toString() ?? '',
//       receiptNumber: json['receiptNumber']?.toString() ?? json['receipt_number']?.toString() ?? '',
//       farmerId: json['farmerId']?.toString() ?? json['farmer_id']?.toString() ?? '',
//       farmerName: json['farmerName']?.toString() ?? json['farmer_name']?.toString() ?? '',
//       farmerMobile: json['farmerMobile']?.toString() ?? json['farmer_mobile']?.toString(),
//       finalPayable: (json['finalPayable'] as num?)?.toDouble() ?? 0,
//       amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
//       amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
//       purchaseDate: DateTime.tryParse(json['purchaseDate']?.toString() ?? json['purchase_date']?.toString() ?? '') ?? DateTime.now(),
//     );
//   }
// }

import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import 'dio_client.dart';
import 'constant_service.dart';
 
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();
 
  final Dio _dio = DioClient.instance.dio;
 
  /// POST /api/payments
  /// Records payment and auto-updates purchase status (partial/paid)
  Future<PaymentModel> recordPayment(PaymentRequest request) async {
    try {
      final response = await _dio.post(
        ApiRoutes.payments,
        data: request.toJson(),
        options: Options(validateStatus: (s) => true),
      );
 
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          // Payment data may be nested under 'data' or at root
          final paymentData = data['data'] ?? data['payment'] ?? data;
          return PaymentModel.fromJson(paymentData as Map<String, dynamic>);
        }
        throw Exception(data['message']?.toString() ?? data['error']?.toString() ?? 'Payment failed');
      }
 
      // Parse error response
      final errorData = response.data;
      String errorMsg = 'Payment failed (${response.statusCode})';
      if (errorData is Map) {
        errorMsg = errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            errorMsg;
      }
      throw Exception(errorMsg);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
 
  /// GET /api/payments with filters
  Future<List<PaymentModel>> getPayments({
    String? purchaseId,
    String? farmerId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (purchaseId != null) params['purchaseId'] = purchaseId;
      if (farmerId != null)   params['farmerId'] = farmerId;
 
      final response = await _dio.get(
        ApiRoutes.payments,
        queryParameters: params,
      );
 
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['data'] as List? ?? data['payments'] as List? ?? [];
        return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
 
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data as Map<String, dynamic>?;
      return data?['message']?.toString() ?? data?['error']?.toString() ?? 'Server error';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return e.message ?? 'Payment failed';
  }
}
 