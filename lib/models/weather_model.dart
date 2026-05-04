class WeatherModel {
  final String city;
  final double temp;
  final double feelsLike;
  final int humidity;
  final String description;
  final double windSpeed;

  WeatherModel({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.windSpeed,
  });

  factory WeatherModel.fromMap(Map<String, dynamic> map) {
    return WeatherModel(
      city:        map['city'] ?? '',
      temp:        double.tryParse(map['temp']?.toString() ?? '0') ?? 0,
      feelsLike:   double.tryParse(map['feels_like']?.toString() ?? '0') ?? 0,
      humidity:    map['humidity'] ?? 0,
      description: map['description'] ?? '',
      windSpeed:   double.tryParse(map['wind_speed']?.toString() ?? '0') ?? 0,
    );
  }

  String get tempText      => '${temp.toStringAsFixed(1)}°C';
  String get feelsLikeText => '${feelsLike.toStringAsFixed(1)}°C';
  String get windText      => '$windSpeed m/s';
  String get humidityText  => '$humidity%';
}

class ForecastModel {
  final String time;
  final double temp;
  final String description;
  final int humidity;

  ForecastModel({
    required this.time,
    required this.temp,
    required this.description,
    required this.humidity,
  });

  factory ForecastModel.fromMap(Map<String, dynamic> map) {
    return ForecastModel(
      time:        map['time'] ?? '',
      temp:        double.tryParse(map['temp']?.toString() ?? '0') ?? 0,
      description: map['description'] ?? '',
      humidity:    map['humidity'] ?? 0,
    );
  }
}