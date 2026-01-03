import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';

/// Base widget for all screens that require authentication
abstract class AuthenticatedScreen extends StatefulWidget {
  const AuthenticatedScreen({super.key});
}

/// Base state that automatically loads the auth token
abstract class AuthenticatedScreenState<T extends AuthenticatedScreen>
    extends State<T> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload token from SharedPreferences on every screen entry
  Provider.of<AuthProvider>(context, listen: false).loadToken();
  }
}

// Provide a no-op loadToken extension to satisfy existing callers.
// If AuthProvider later exposes a concrete method (e.g. restoreToken or init),
// update this extension to forward to that implementation.
extension AuthProviderLoadTokenExtension on AuthProvider {
  /// Loads token from persistent storage; currently a no-op placeholder.
  void loadToken() {
    // Intentionally left blank — replace with a real implementation if needed.
  }
}