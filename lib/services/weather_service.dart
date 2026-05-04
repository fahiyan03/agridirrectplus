import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeatherMap API key
  // যদি account করতে না পারো তাহলে _apiKey খালি রাখো
  // অ্যাপ তখন dummy data দেখাবে
  static const String _apiKey = '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> getCurrentWeather({
    double lat = 23.8103,
    double lon = 90.4125,
  }) async {
    // API key না থাকলে dummy data দাও
    if (_apiKey.isEmpty) return getDummyWeather();

    try {
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=bn';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temp': (data['main']['temp'] as num).toStringAsFixed(1),
          'feels_like': (data['main']['feels_like'] as num).toStringAsFixed(1),
          'humidity': data['main']['humidity'],
          'description': data['weather'][0]['description'],
          'wind_speed': data['wind']['speed'],
          'city': data['name'],
        };
      }
      return getDummyWeather();
    } catch (_) {
      return getDummyWeather();
    }
  }

  Future<List<Map<String, dynamic>>> getForecast({
    double lat = 23.8103,
    double lon = 90.4125,
  }) async {
    if (_apiKey.isEmpty) return getDummyForecast();

    try {
      final url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=bn&cnt=5';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'];
        return list.map((item) => {
          'time': item['dt_txt'],
          'temp': (item['main']['temp'] as num).toStringAsFixed(1),
          'description': item['weather'][0]['description'],
          'humidity': item['main']['humidity'],
        }).toList();
      }
      return getDummyForecast();
    } catch (_) {
      return getDummyForecast();
    }
  }

  // OpenWeatherMap account না থাকলে এই dummy data দেখাবে
  Map<String, dynamic> getDummyWeather() {
    return {
      'temp': '28.5',
      'feels_like': '31.0',
      'humidity': 72,
      'description': 'আংশিক মেঘলা',
      'wind_speed': 3.2,
      'city': 'ঢাকা',
    };
  }

  List<Map<String, dynamic>> getDummyForecast() {
    return [
      {'time': 'আজ সকাল', 'temp': '28', 'description': 'রৌদ্রজ্জ্বল', 'humidity': 68},
      {'time': 'আজ দুপুর', 'temp': '32', 'description': 'গরম', 'humidity': 65},
      {'time': 'আজ বিকেল', 'temp': '29', 'description': 'আংশিক মেঘলা', 'humidity': 75},
      {'time': 'আগামীকাল', 'temp': '27', 'description': 'হালকা বৃষ্টি', 'humidity': 85},
      {'time': 'পরশু', 'temp': '26', 'description': 'মেঘলা', 'humidity': 80},
    ];
  }
}