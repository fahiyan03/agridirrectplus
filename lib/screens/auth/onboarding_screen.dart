import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.agriculture_rounded,
      color: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFE8F5E9),
      title: 'সরাসরি কৃষক থেকে কিনুন',
      subtitle: 'মধ্যস্বত্বভোগী ছাড়াই তাজা ফসল সংগ্রহ করুন। কৃষক ন্যায্য মূল্য পাবেন, আপনি পাবেন তাজা পণ্য।',
    ),
    _OnboardingData(
      icon: Icons.location_on_rounded,
      color: const Color(0xFF00838F),
      bgColor: const Color(0xFFE0F7FA),
      title: 'জোন ভিত্তিক ডেলিভারি',
      subtitle: 'আপনার কাছের কৃষকের পণ্য আজকেই পান। দূরত্ব অনুযায়ী ৪টি জোনে ভাগ করা — একই দিনে থেকে সারাদেশে।',
    ),
    _OnboardingData(
      icon: Icons.biotech_rounded,
      color: const Color(0xFFF57F17),
      bgColor: const Color(0xFFFFFDE7),
      title: 'AI দিয়ে ফসলের রোগ নির্ণয়',
      subtitle: 'Crop Doctor ফিচার দিয়ে ফসলের ছবি তুলুন। AI তাৎক্ষণিক রোগ শনাক্ত করে চিকিৎসার পরামর্শ দেবে।',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [

          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _goToLogin,
              child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages[_currentPage].color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'শুরু করুন' : 'পরবর্তী',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login link
          TextButton(
            onPressed: _goToLogin,
            child: const Text(
              'ইতিমধ্যে অ্যাকাউন্ট আছে? লগইন করুন',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 80, color: data.color),
          ),

          const SizedBox(height: 40),

          Text(
            data.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });
}