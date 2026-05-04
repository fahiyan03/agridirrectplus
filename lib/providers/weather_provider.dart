import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final _service = WeatherService();

  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get current  => _current;
  List<Map<String, dynamic>> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error  => _error;
  bool get hasData   => _current != null;

  Future<void> loadWeather({double lat = 23.8103, double lon = 90.4125}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _current  = await _service.getCurrentWeather(lat: lat, lon: lon);
      _forecast = await _service.getForecast(lat: lat, lon: lon);
    } catch (_) {
      // Error হলে dummy data দেখাও
      _current  = _service.getDummyWeather();
      _forecast = _service.getDummyForecast();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quick getters
  String get tempText        => _current?['temp'] != null ? '${_current!['temp']}°C' : '--';
  String get descriptionText => _current?['description'] ?? '';
  String get humidityText    => _current?['humidity'] != null ? '${_current!['humidity']}%' : '--';
  String get windText        => _current?['wind_speed'] != null ? '${_current!['wind_speed']} m/s' : '--';
  String get cityText        => _current?['city'] ?? 'আপনার এলাকা';
}