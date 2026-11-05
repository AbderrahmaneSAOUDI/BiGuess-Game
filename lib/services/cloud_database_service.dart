import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/game_record.dart';

/// Provider for [CloudDatabaseService] instance
final cloudDatabaseServiceProvider = Provider<CloudDatabaseService>((ref) {
  return CloudDatabaseService();
});

/// Service responsible for communicating with Cloudflare D1 database
/// via the deployed Cloudflare Worker API.
class CloudDatabaseService {
  final Dio _dio;

  static const String defaultEndpoint =
      'https://biguess-api.biguess-api.workers.dev';

  CloudDatabaseService({Dio? dio, String baseUrl = defaultEndpoint})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Checks the connectivity and health status of the Cloudflare Worker API.
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      if (response.statusCode == 200 && response.data != null) {
        return response.data!['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches recent game match records from Cloudflare D1.
  Future<List<GameRecord>> fetchRecords() async {
    try {
      final response = await _dio.get<List<dynamic>>('/records');
      if (response.statusCode == 200 && response.data != null) {
        return response.data!
            .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw Exception('Failed to load records from Cloudflare D1: ${e.message}');
    }
  }

  /// Saves a completed game record to Cloudflare D1.
  ///
  /// Returns the newly inserted record ID if successful.
  Future<int?> saveGameRecord(GameRecord record) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/records',
        data: record.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final rawId = response.data!['id'];
        return rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Failed to save record to Cloudflare D1: ${e.message}');
    }
  }
}
