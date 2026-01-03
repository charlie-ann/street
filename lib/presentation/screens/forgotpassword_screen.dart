import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street/presentation/widgets/menu_button.dart';
import 'package:street/presentation/widgets/textformfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF1A0033)], // Dark black to deep purple gradient
              ),
            ),
          ),
          // Top cyan glow circle
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withValues(alpha: 0.5,blue: 0.5, red: 0.2, green: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.5,blue: 0.5, red: 0.2, green: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Bottom purple glow
          Positioned(
            bottom: 100,
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9C27B0).withValues(alpha: 0.5,blue: 0.5, red: 0.5, green: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.5,blue: 0.5, red: 0.5, green: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                 // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120), // Adjust for top glow
                    const Text(
                      
                      'Reset Your Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        children: [
                          TextSpan(text: 'You\'ll receive an OTP to reset your password '),
                          
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                     Align(
                      alignment: Alignment.centerLeft,
                       child: RichText(
                        textAlign: TextAlign.start,
                        text: const TextSpan(
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Email Address',
                            ),
                          ],
                        ),
                                           ),
                     ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      labelText: 'Enter your email',
                    ),
                    const SizedBox(height: 28),
                    MenuButton(
                      text: _isLoading ? 'Sending...' : 'Send Reset Link ',
                      suffixIcon: Icons.send_outlined,
                      onPressed: () {
                        if (_isLoading) return;
                        if (_emailController.text.isNotEmpty) {
                          setState(() => _isLoading = true);
                          Future.delayed(const Duration(seconds: 2)).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reset link sent to your email')),
                            );
                            context.go('/otp');
                            setState(() => _isLoading = false);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    // Bottom purple glow for link
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => context.go('/authentication'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            children: [
                              TextSpan(text: 'Remember your password? '),
                              TextSpan(
                                text: '   Sign In',
                                style: TextStyle(color: Colors.lightBlueAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // Adjust for bottom glow
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}