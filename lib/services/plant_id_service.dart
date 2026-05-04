import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PlantIdService {
  // তোমার API key এখানে আছে - ঠিক আছে
  static const String _apiKey = 'TVZV39PSHykqa7564h9eOMnFFrNrjEHnsDre6NqIcwYQZa0JWn';
  // v3 URL - তুমি ঠিকই করেছো
  static const String _baseUrl = 'https://plant.id/api/v3';

  Future<Map<String, dynamic>> identifyDisease(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // v3 API এর নতুন endpoint ও format
    final response = await http.post(
      Uri.parse('$_baseUrl/health_assessment'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': _apiKey,
      },
      body: json.encode({
        'images': ['data:image/jpeg;base64,$base64Image'],
        'health': 'all',
        'disease_details': ['cause', 'common_names', 'treatment'],
        'similar_images': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return _parseResponse(data);
    } else {
      throw Exception('রোগ শনাক্ত করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  Map<String, dynamic> _parseResponse(Map<String, dynamic> data) {
    // v3 এর response structure
    final result = data['result'];
    if (result == null) {
      return {'is_healthy': true, 'message': 'ফসল সুস্থ দেখাচ্ছে!', 'diseases': []};
    }

    final isHealthy = result['is_healthy']?['binary'] ?? true;

    if (isHealthy) {
      return {
        'is_healthy': true,
        'message': 'আপনার ফসল সুস্থ দেখাচ্ছে!',
        'diseases': [],
      };
    }

    final diseases = (result['disease']?['suggestions'] as List?) ?? [];
    final topDiseases = diseases.take(3).map((d) {
      final details = d['details'] ?? {};
      final treatment = details['treatment'] ?? {};
      return {
        'name': d['name'] ?? 'অজানা রোগ',
        'probability': (((d['probability'] ?? 0) as num) * 100).toStringAsFixed(0),
        'common_names': (details['common_names'] as List?)?.join(', ') ?? '',
        'treatment_biological': treatment['biological'] ?? '',
        'treatment_chemical': treatment['chemical'] ?? '',
        'treatment_prevention': treatment['prevention'] ?? '',
      };
    }).toList();

    return {
      'is_healthy': false,
      'diseases': topDiseases,
    };
  }
}