import 'dart:collection';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../models/buildings.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSwitch;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onSwitch,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedBuilding;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBuilding == null) {
      setState(() {
        _error = 'Please select your building.';
      });
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a username.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        building: _selectedBuilding!,
        username: _usernameController.text.trim(),
      );
    } catch (error) {
      setState(() {
        _error = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dedupedBuildings = LinkedHashSet<String>.from(
      kBuildings.map((value) => value.trim()),
    ).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111215) : const Color(0xFFFAFAFA);
    final panelFill = isDark ? const Color(0xFF1A1C20) : const Color(0xFFF1F1F1);
    final borderColor = isDark ? const Color(0xFF2A2D33) : const Color(0xFFDBDBDB);
    final mainText = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final subText = isDark ? const Color(0xFFB7BDC7) : const Color(0xFF5E5E5E);
    final linkColor = isDark ? const Color(0xFF7DB6FF) : const Color(0xFF00376B);
    final dividerColor = isDark ? const Color(0xFF2A2D33) : const Color(0xFFDBDBDB);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    );
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Image.asset(
                        'assets/images/quakenav_logo_inapp.png',
                        width: 92,
                        height: 92,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create your QuakeNav account',
                        style: TextStyle(
                          color: subText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: mainText),
                      decoration: InputDecoration(
                        hintText: 'Full name',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _addressController,
                      style: TextStyle(color: mainText),
                      decoration: InputDecoration(
                        hintText: 'Address',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: mainText),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedBuilding,
                      decoration: InputDecoration(
                        hintText: 'Building',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      items: dedupedBuildings
                          .map(
                            (building) => DropdownMenuItem<String>(
                              value: building,
                              child: Text(
                                building,
                                style: TextStyle(color: mainText),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBuilding = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: mainText),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: mainText),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: panelFill,
                        hintStyle: TextStyle(color: subText),
                        enabledBorder: border,
                        focusedBorder: border,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4CB5F9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_loading ? 'Creating...' : 'Sign up'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: subText),
                  ),
                  GestureDetector(
                    onTap: widget.onSwitch,
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        color: linkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
