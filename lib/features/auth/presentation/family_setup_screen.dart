import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isJoiningFamily = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      // Sign up first if not already authenticated
      var user = authService.getCurrentUser();
      if (user == null) {
        await authService.createAccountWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        user = authService.getCurrentUser();
        // Wait for auth state to fully settle
        user ??= await authService.authStateChanges().firstWhere((u) => u != null);
      }

      if (user == null) throw Exception('Sign-up failed. Please try again.');

      await authService.createFamily(_familyNameController.text.trim());

      if (mounted) {
        context.go('/parent-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      // Sign up first if not already authenticated
      var user = authService.getCurrentUser();
      if (user == null) {
        await authService.createAccountWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        user = authService.getCurrentUser();
        user ??= await authService.authStateChanges().firstWhere((u) => u != null);
      }

      if (user == null) throw Exception('Sign-up failed. Please try again.');

      final inviteCode = _inviteCodeController.text.trim();
      
      // Add parent to the family using repository
      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.addParent(
        familyId: inviteCode,
        parentUid: user.uid,
        parentDisplayName: user.displayName ?? user.email?.split('@')[0] ?? 'Parent',
        isOwner: false,
      );
      
      if (mounted) {
        context.go('/parent-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('not found') || e.toString().contains('NOT_FOUND')
                  ? 'Invalid family code. Please check and try again.'
                  : e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final isAlreadyLoggedIn = authState.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isJoiningFamily ? 'Join a Family' : 'Create Your Family'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Welcome to KidsFinance! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _isJoiningFamily
                      ? 'Create an account and join your family'
                      : "Create an account to get started",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Toggle between Create and Join
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isJoiningFamily = false),
                        icon: const Icon(Icons.family_restroom),
                        label: const Text('Create New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isJoiningFamily
                              ? Colors.grey.shade200
                              : Theme.of(context).primaryColor,
                          foregroundColor:
                              _isJoiningFamily ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isJoiningFamily = true),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Existing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isJoiningFamily
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade200,
                          foregroundColor:
                              _isJoiningFamily ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Email + password fields for new users
                if (!isAlreadyLoggedIn) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Family name or invite code
                if (_isJoiningFamily)
                  TextFormField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Family Invite Code',
                      hintText: 'Enter the code shared by another parent',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the family invite code';
                      }
                      if (value.trim().length < 10) {
                        return 'Invalid code format';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _familyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Family Name',
                      hintText: 'e.g., The Smith Family',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a family name';
                      }
                      if (value.trim().length < 2) {
                        return 'Family name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isJoiningFamily ? _joinFamily : _createFamily),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isJoiningFamily ? 'Join Family' : 'Create Family',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isJoiningFamily
                      ? 'Ask another parent to share their Family Code from the app settings.'
                      : 'You can add children and invite other parents after creating your family.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
