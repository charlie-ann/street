import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street/core/constants.dart';
import '../widgets/menu_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter ,
            end: Alignment.center,
            colors: [Colors.black, Color(0xFF4A148C)], // Dark to deep purple
          ),
        ),
        child: Stack(
          children: [
            _buildPage(AppConstants.backgroundImage, 'Play. Bet. Win.', 'Experience the thrill of multiple games in one platform.'),
          
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: MenuButton(
                text: 'Get Started',
                onPressed: () => context.go('/auth'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String image, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2,blue: 0.2, red: 0.2, green: 0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 200),
              ),
            ),
          ),
          const SizedBox(height: 40),
         Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
         const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

 
}