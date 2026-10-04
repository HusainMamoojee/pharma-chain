import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/totp.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class Staff2FAEnrollScreen extends StatefulWidget {
  const Staff2FAEnrollScreen({super.key});

  @override
  State<Staff2FAEnrollScreen> createState() => _Staff2FAEnrollScreenState();
}

class _Staff2FAEnrollScreenState extends State<Staff2FAEnrollScreen> {
  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  late final String _secret;
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _secret = _generateSecret();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _generateSecret({int length = 32}) {
    final random = Random.secure();
    return List.generate(length, (_) => _base32Alphabet[random.nextInt(_base32Alphabet.length)]).join();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  String get _otpAuthUri {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'staff';
    return 'otpauth://totp/PharmaChain:$email?secret=$_secret&issuer=PharmaChain&algorithm=SHA1&digits=6&period=30';
  }

  bool _codeMatches(String code) {
    return Totp.verify(_secret, code);
  }

  Future<void> _handleConfirm() async {
    if (_enteredCode.length != 6) {
      setState(() => _error = 'Enter the full 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    if (!_codeMatches(_enteredCode)) {
      setState(() {
        _isVerifying = false;
        _error = 'Incorrect code. Check the time on your device and app.';
      });
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'totpSecret': _secret, 'totpEnabled': true},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      context.go('/staff-dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = 'Could not save setup. Please try again.';
      });
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
          child: Column(
            children: [
              Icon(Icons.qr_code_2, size: 48, color: AppColors.tertiary),
              const SizedBox(height: 16),
              Text(
                'Set Up Two-Factor Authentication',
                style: AppTextStyles.headline.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this code with Google Authenticator, Authy, or a similar app',
                style: AppTextStyles.body.copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _otpAuthUri,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Can't scan? Enter this code manually:",
                style: AppTextStyles.body.copyWith(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _secret,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', letterSpacing: 2),
              ),
              const SizedBox(height: 32),
              Text(
                'Then enter the 6-digit code it shows',
                style: AppTextStyles.body.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.tertiary, width: 1.5),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(value, index),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: AppColors.neutral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isVerifying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neutral),
                        )
                      : Text('Confirm & Enable', style: AppTextStyles.label.copyWith(color: AppColors.neutral)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}