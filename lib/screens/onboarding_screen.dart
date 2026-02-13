import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import '../services/local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final LocalStorageService _storageService = LocalStorageService();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Import Effortlessly',
      description:
          'Upload your timetable from Excel, PDF, or even a screenshot.',
      icon: Icons.upload_file,
    ),
    OnboardingData(
      title: 'Smart Scheduling',
      description:
          'Automatically detect conflicts and get smart study suggestions.',
      icon: Icons.smart_toy_outlined,
    ),
    OnboardingData(
      title: 'Focus Mode',
      description:
          'Banish distractions during study sessions with deep focus mode.',
      icon: Icons.timer_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      await _storageService.setOnboardingComplete(true);
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.vibrantTeal : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 100, color: AppColors.vibrantTeal),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
