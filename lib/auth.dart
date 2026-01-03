// lib/presentation/auth/authentication_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/game_provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/widgets/menu_button.dart';
import 'package:street/presentation/widgets/textformfield.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  // Controllers ---------------------------------------------------------------
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _loginFieldController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // UI state -----------------------------------------------------------------
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLogin = true;
  bool _isSignUp = false;
  bool _isLoading = false;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // -------------------------------------------------------------------------
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load persisted token (and therefore the balance) once the widget is in the tree
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadToken();          // loads token from SharedPreferences
    authProvider.loadWalletBalance();  // loads saved balance (if any)
  }

  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color.fromARGB(255, 1, 48, 72),
              Color.fromARGB(255, 0, 0, 0)
            ], // Dark to deep purple
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/poker.png',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported, size: 150),
                    ),
                  ),

                  // Login / Sign-Up toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _isLogin = true;
                          _isSignUp = false;
                        }),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              _isLogin ? Colors.blue : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(' Login ',
                            style: TextStyle(
                                color: _isLogin ? Colors.white : Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isSignUp = true;
                          _isLogin = false;
                        }),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              _isSignUp ? Colors.blue : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Sign Up',
                            style: TextStyle(
                                color: _isSignUp ? Colors.white : Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------- SIGN-UP ONLY FIELDS ----------
                  if (_isSignUp)
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                          ),
                        ),
                      ],
                    ),
                  if (_isSignUp) const SizedBox(height: 16),
                  if (_isSignUp)
                    CustomTextField(
                      controller: _userNameController,
                      labelText: 'Username',
                    ),
                  if (_isSignUp) const SizedBox(height: 16),

                  // ---------- SHARED FIELD (login identifier / email) ----------
                  CustomTextField(
                    controller: _isLogin ? _loginFieldController : _emailController,
                    labelText: _isLogin ? 'Username or Email' : 'Email Address',
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),

                  // Confirm password (sign-up only)
                  if (_isSignUp) const SizedBox(height: 16),
                  if (_isSignUp)
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),

                  const SizedBox(height: 8),

                  // Remember-me & forgot password (login only)
                  if (_isLogin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v!),
                              checkColor: Colors.white,
                              activeColor: Colors.blue,
                            ),
                            const Text('Remember me',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/forgotpassword'),
                          child: const Text('Forgot password?',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.blue)),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Submit button + loader
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    MenuButton(
                      text: _isLogin ? 'Sign In' : 'Create Account',
                      onPressed: _handleAuth,
                    ),

                  const SizedBox(height: 24),

                  // Divider "Or continue with"
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Or continue with',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google button
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.g_translate, color: Colors.white),
                    label: const Text('Continue with Google',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(143, 66, 66, 66),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Apple button
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Apple sign-in
                    },
                    icon: const Icon(Icons.apple, color: Colors.white),
                    label: const Text('Continue with Apple',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(143, 66, 66, 66),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
Future<void> _handleAuth() async {
  final gameProvider = Provider.of<GameProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  setState(() => _isLoading = true);

  try {
    // -------------------------- LOGIN --------------------------
   if (_isLogin) {
  if (_loginFieldController.text.isEmpty || _passwordController.text.isEmpty) {
    _showSnack('Please fill in all fields');
    return;
  }

  debugPrint('DEBUG: Sending login request to ${Endpoints.login}');
final response = await http.post(
  Uri.parse(Endpoints.login),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'identifier': _loginFieldController.text.trim(),
    'password': _passwordController.text,
  }),
);

debugPrint('DEBUG: Response Code: ${response.statusCode}');
debugPrint('DEBUG: Response Body: ${response.body}');

if (response.statusCode == 200 || response.statusCode == 201) {
  try {
    final data = json.decode(response.body);
    debugPrint('DEBUG: Login response data: $data');

    // Extract token and user data
    final String? token = data['token']?.toString();
    final userData = data['user'] ?? data; // Handle both nested and flat structures
    
    final String? userId = (userData['_id'] ?? userData['id'])?.toString();
    final String username = userData['username']?.toString() ?? _loginFieldController.text;
    final double balance = double.tryParse(userData['walletBalance']?.toString() ?? '0') ?? 0.0;

    debugPrint('DEBUG: Extracted - Token: ${token?.substring(0, 20)}..., UserID: $userId, Username: $username, Balance: $balance');

    // Validate required fields
    if (token == null || token.isEmpty || token.length < 20) {
      _showSnack('Login failed: Invalid token from server');
      return;
    }
    
    if (userId == null || userId.isEmpty) {
      _showSnack('Login failed: No user ID received');
      return;
    }

    // Save all user data
    await Provider.of<AuthProvider>(context, listen: false).saveUserData(
      token: token,
      userId: userId,
      username: username,
      walletBalance: balance,
    );

    // Update game provider
    gameProvider.updatePlayerName(username);

    // Success!
    _showSnack('Welcome back, $username!');

    // Navigate to home
    if (mounted) {
      context.go('/home');
    }
  } catch (e) {
    debugPrint('JSON Parse Error: $e');
    _showSnack('Login failed: Server error');
  }
} else {
  try {
    final error = json.decode(response.body);
    _showSnack(error['message'] ?? 'Invalid credentials');
  } catch (e) {
    _showSnack('Login failed. Try again.');
  }
}

    } else {
      // -------------------------- SIGN-UP --------------------------
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _userNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty ||
          _passwordController.text != _confirmPasswordController.text) {
        _showSnack('Please fill all fields and match passwords');
        return;
      }

      final response = await http.post(
        Uri.parse(Endpoints.signup),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'username': _userNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode != 201) {
        final data = json.decode(response.body);
        _showSnack(data['message'] ?? 'Signup failed');
        return;
      }

      final data = json.decode(response.body);
     // final String? token = data['token']?.toString();
      final double balance = double.tryParse(data['walletBalance']?.toString() ?? '') ?? 0.0;

      // if (token == null || token.isEmpty) {
      //   _showSnack('Signup failed: No token received');
      //   return;
      // }

      //await authProvider.setToken(token);
      await authProvider.setWalletBalance(balance);
      gameProvider.updatePlayerName(_userNameController.text);

      if (mounted) context.go('/home');
    }
  } catch (e) {
    debugPrint('Network error details: $e');
    String errorMessage = 'Network error: $e';
    
    if (e.toString().contains('SocketException')) {
      errorMessage = 'Cannot connect to server: ${e.toString()}';
    } else if (e.toString().contains('Failed host lookup')) {
      errorMessage = 'Server not found: ${e.toString()}';
    } else if (e.toString().contains('TimeoutException')) {
      errorMessage = 'Connection timeout: ${e.toString()}';
    } else if (e.toString().contains('HandshakeException')) {
      errorMessage = 'SSL/Certificate error: ${e.toString()}';
    }
    
    _showSnack(errorMessage);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// Helper
void _showSnack(String msg) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// Google Sign-In handler
Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      _showSnack('Google Sign-In cancelled');
      return;
    }
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Send Google token to your backend for verification
    final response = await http.post(
      Uri.parse('${Endpoints.baseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      debugPrint('DEBUG: Google login response: $data');
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final userData = data['user'] ?? data;
      final String? userId = (userData['_id'] ?? userData['id'])?.toString();
      final String username = userData['username']?.toString() ?? googleUser.displayName ?? 'GoogleUser';
      final double balance = userData['walletBalance']?.toDouble() ?? 1000.0;
      
      await authProvider.saveUserData(
        token: data['token'],
        userId: userId ?? googleUser.id,
        username: username,
        walletBalance: balance,
      );
      
      gameProvider.updatePlayerName(username);
      _showSnack('Welcome, ${googleUser.displayName}!');
      
      if (mounted) context.go('/home');
    } else {
      // Fallback: create local user with Google info
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await authProvider.saveUserData(
        token: 'google_${googleUser.id}',
        userId: googleUser.id,
        username: googleUser.displayName ?? 'GoogleUser',
        walletBalance: 1000.0,
      );
      
      gameProvider.updatePlayerName(googleUser.displayName ?? 'GoogleUser');
      _showSnack('Welcome, ${googleUser.displayName}!');
      
      if (mounted) context.go('/home');
    }
  } catch (e) {
    _showSnack('Google Sign-In failed: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
}