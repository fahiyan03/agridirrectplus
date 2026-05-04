import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final VoidCallback? onTap;

  const WeatherWidget({
    super.key,
    required this.weather,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        )
            : Row(children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('আজকের আবহাওয়া',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                weather != null
                    ? '${weather!['temp']}°C - ${weather!['description']}'
                    : 'তথ্য পাওয়া যায়নি',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (weather != null)
                Text(
                  'আর্দ্রতা: ${weather!['humidity']}% | বায়ু: ${weather!['wind_speed']} m/s',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ]),
          ),
          if (onTap != null)
            const Text('বিস্তারিত', style: TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    );
  }
}