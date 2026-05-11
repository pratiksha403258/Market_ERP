import 'package:agr_market/models/sale_model.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';

class SaleService {
  SaleService._();
  static final instance = SaleService._();
  final Dio _dio = DioClient.instance.dio;

  Future<List<SaleModel>> getSales({int page = 1, int limit = 20}) async {
    final res = await _dio.get(ApiRoutes.sales, queryParameters: {'page': page, 'limit': limit});
    final list = (res.data['data'] as List).map((e) => SaleModel.fromJson(e)).toList();
    return list;
  }

  Future<SaleModel> createSale(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiRoutes.sales, data: data);
    return SaleModel.fromJson(res.data['data']);
  }

  Future<String> getInvoicePdfUrl(String saleId) async {
    final res = await _dio.get(ApiRoutes.saleInvoice(saleId));
    return res.data['pdfUrl'];
  }
}