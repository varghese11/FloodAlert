import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/water_reading.dart';

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override String toString() => 'NetworkException: $message';
}

class ApiTimeoutException implements Exception {
  final String message;
  ApiTimeoutException(this.message);
  @override String toString() => 'ApiTimeoutException: $message';
}

class WaterStation {
  static const String kallooppara = '017-SWRDKOCHI';
  static const String pullakkayar = '035-SWRDKOCHI';
}

class WaterApiService {
  static const _baseUrl =
      'https://ffs.india-water.gov.in/iam/api/new-entry-data/specification/sorted';
  static const _datatypeCode = 'HHS';

  final Dio _dio;

  WaterApiService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<List<WaterReading>> fetchReadings({
    String stationCode = WaterStation.kallooppara,
    Duration lookback = const Duration(hours: 72),
  }) async {
    final now = DateTime.now();
    final from = now.subtract(lookback);

    final sortCriteria = jsonEncode({
      "sortOrderDtos": [
        {"sortDirection": "ASC", "field": "id.dataTime"}
      ]
    });

    final specification = _buildSpecification(stationCode, from, now);

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'sort-criteria': sortCriteria,
          'specification': specification,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => WaterReading.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiTimeoutException('Connection timed out');
      }
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw NetworkException('Failed to parse response: $e');
    }
  }

  String _buildSpecification(String stationCode, DateTime from, DateTime now) {
    return jsonEncode({
      "where": {
        "where": {
          "where": {
            "expression": {
              "valueIsRelationField": false,
              "fieldName": "id.stationCode",
              "operator": "eq",
              "value": stationCode,
            }
          },
          "and": {
            "expression": {
              "valueIsRelationField": false,
              "fieldName": "id.datatypeCode",
              "operator": "eq",
              "value": _datatypeCode
            }
          }
        },
        "and": {
          "expression": {
            "valueIsRelationField": false,
            "fieldName": "dataValue",
            "operator": "null",
            "value": "false"
          }
        }
      },
      "and": {
        "expression": {
          "valueIsRelationField": false,
          "fieldName": "id.dataTime",
          "operator": "btn",
          "value": "${_formatForApi(from)},${_formatForApi(now)}"
        }
      }
    });
  }

  // Format: "2022-08-04T17:00:00.000" — matches the API sample (no trailing Z)
  String _formatForApi(DateTime dt) =>
      dt.toIso8601String().substring(0, 23);
}
