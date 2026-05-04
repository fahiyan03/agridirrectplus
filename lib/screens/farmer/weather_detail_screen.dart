import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/weather_service.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});
  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);
    final service = WeatherService();
    try {
      final current = await service.getCurrentWeather();
      final forecast = await service.getForecast();
      setState(() {
        _current = current;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (_) {
      // Error হলে dummy data দেখাও - কোনো error screen দেখাবে না
      setState(() {
        _current = service.getDummyWeather();
        _forecast = service.getDummyForecast();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        title: const Text('আবহাওয়ার বিস্তারিত'),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
        onRefresh: _loadWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [

            // ── Current Weather ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text(
                  _current?['city'] ?? 'আপনার এলাকা',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_current?['temp']}°C',
                  style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w200),
                ),
                Text(
                  _current?['description'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _WeatherStat(icon: Icons.water_drop_rounded, label: 'আর্দ্রতা', value: '${_current?['humidity']}%'),
                  _WeatherStat(icon: Icons.air_rounded, label: 'বায়ু', value: '${_current?['wind_speed']} m/s'),
                  _WeatherStat(icon: Icons.thermostat_rounded, label: 'অনুভব', value: '${_current?['feels_like']}°C'),
                ]),
              ]),
            ),

            // ── Forecast + Tips ──
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const Text('পূর্বাভাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                if (_forecast.isEmpty)
                  const Text('পূর্বাভাস পাওয়া যায়নি', style: TextStyle(color: AppColors.textSecondary))
                else
                  ..._forecast.map((f) => _ForecastTile(forecast: f)),

                const SizedBox(height: 20),

                // ── Farming Tips ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text('কৃষি পরামর্শ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                    ]),
                    const SizedBox(height: 8),
                    ..._getFarmingTips().map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      ]),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  List<String> _getFarmingTips() {
    final temp = double.tryParse(_current?['temp']?.toString() ?? '25') ?? 25;
    final humidity = int.tryParse(_current?['humidity']?.toString() ?? '60') ?? 60;

    final tips = <String>[];
    if (temp > 35) tips.add('তাপমাত্রা বেশি - সেচ বাড়িয়ে দিন এবং ফসল ছায়ায় রাখুন');
    if (temp < 15) tips.add('তাপমাত্রা কম - শীতকালীন ফসলের জন্য ভালো সময়');
    if (humidity > 80) tips.add('আর্দ্রতা বেশি - ছত্রাক রোগের সম্ভাবনা আছে, খেয়াল রাখুন');
    if (humidity < 40) tips.add('আর্দ্রতা কম - ফসলে নিয়মিত সেচ দিন');
    tips.add('ভোরবেলা বা সন্ধ্যায় সেচ দেওয়া সবচেয়ে কার্যকর');
    return tips;
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _WeatherStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}

class _ForecastTile extends StatelessWidget {
  final Map<String, dynamic> forecast;
  const _ForecastTile({required this.forecast});

  @override
  Widget build(BuildContext context) {
    // substring এর বদলে safe truncation ব্যবহার করা হয়েছে
    // এটাই RangeError এর সমাধান
    final timeText = forecast['time']?.toString() ?? '';
    final displayTime = timeText.length > 16 ? timeText.substring(0, 16) : timeText;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.wb_cloudy_rounded, color: Color(0xFF1565C0), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(displayTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Text('${forecast['temp']}°C', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            forecast['description'] ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}