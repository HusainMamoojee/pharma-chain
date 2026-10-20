import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/gateway_service.dart';

class PatientVerificationScreen extends StatefulWidget {
  const PatientVerificationScreen({super.key});

  @override
  State<PatientVerificationScreen> createState() => _PatientVerificationScreenState();
}

class _PatientVerificationScreenState extends State<PatientVerificationScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();

  bool _isProcessing = false;
  bool _sheetOpen = false;
  bool _scannerStopped = false;
  bool _cameraFailed = false;
  bool _permissionDenied = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // SCANNING + VERIFICATION
  // ---------------------------------------------------------------

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _sheetOpen) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();
    _scannerStopped = true;
    _verifyCode(code);
  }

  void _handleManualSubmit() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    _manualCodeController.clear();
    setState(() => _isProcessing = true);
    _verifyCode(code);
  }

    Future<void> _verifyCode(String rawCode) async {
    final code = rawCode.trim();
    String resolvedCode = code;
    Map<String, dynamic> result = {'exists': false};

    try {
      // The ledger only holds codes up to 64 characters; anything longer
      // (for example a URL in a QR code) cannot be a batch.
      if (code.isNotEmpty && code.length <= 64) {
        result = await GatewayService.instance.verifyBatch(code);

        // Be forgiving about typing in lower case.
        if (result['exists'] != true && code != code.toUpperCase()) {
          final alt = await GatewayService.instance.verifyBatch(code.toUpperCase());
          if (alt['exists'] == true) {
            result = alt;
            resolvedCode = code.toUpperCase();
          }
        }
      }
    } catch (e) {
      // The ledger could not be reached or asked: say so, never guess "counterfeit".
      if (!mounted) return;
      final message = e is GatewayException ? e.message : "Couldn't check that code. Please try again.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await _resetAfterAttempt();
      return;
    }

    final exists = result['exists'] == true;
    final ledgerStatus = result['status'] as String? ?? 'Not recognised';
    final productName = result['productName'] as String? ?? resolvedCode;
    final status = !exists ? 'Under Review' : (ledgerStatus == 'Expired' ? 'Expired' : 'Authentic');

    // Record the attempt. A failure here shouldn't hide the result.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('verifications').add({
          'userId': uid,
          'batchCode': resolvedCode,
          'productName': productName,
          'status': status,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Could not save verification: $e');
      }
    }

    if (!mounted) return;

    if (exists) {
      await context.push('/validation-success', extra: {
        'code': resolvedCode,
        'data': {
          'productName': result['productName'],
          'expiryDate': result['expiryDate'],
          'organizationId': result['manufacturerOrgId'],
        },
      });
    } else {
      await context.push('/counterfeit-catch', extra: {'code': resolvedCode});
    }

    await _resetAfterAttempt();
  }

  /// Hide the spinner and bring the camera back after a result screen.
  Future<void> _resetAfterAttempt() async {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (_scannerStopped && !_cameraFailed) {
      try {
        await _scannerController.start();
        _scannerStopped = false;
      } catch (e) {
        debugPrint('Could not restart scanner: $e');
      }
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------
  // MANUAL ENTRY
  // ---------------------------------------------------------------

  Future<void> _showManualEntrySheet() async {
    _sheetOpen = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        void submit() {
          if (_manualCodeController.text.trim().isEmpty) return;
          Navigator.of(sheetContext).pop();
          _handleManualSubmit();
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Enter Code Manually',
                    style: AppTextStyles.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  'Type the batch code printed on the packaging',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _manualCodeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    hintText: 'e.g. BATCH-4521-ZA',
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Verify Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Sheet dismissed (submitted or swiped away).
    _sheetOpen = false;
    if (!_isProcessing) _manualCodeController.clear();
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  Widget _buildCameraError() {
    final title = _permissionDenied ? 'Camera access is off' : 'Camera unavailable';
    final message = _permissionDenied
        ? 'Allow camera access in Settings > PharmaChain to scan packaging. '
            'You can still enter the batch code below.'
        : "We couldn't start the camera on this device. "
            'You can still enter the batch code below.';

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
                        errorBuilder: (BuildContext context, MobileScannerException error,
                [Widget? child]) {
              if (!_cameraFailed) {
                final denied = error.errorCode.name == 'permissionDenied';
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _cameraFailed = true;
                      _permissionDenied = denied;
                    });
                  }
                });
              }
              return _buildCameraError();
            },
  
          ),

          // Viewfinder frame (only when the camera is working)
          if (!_cameraFailed)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _close,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Text(
                    'Scan Medicine Packaging',
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                  // Keeps the title centred when the flash button is hidden.
                  _cameraFailed
                      ? const SizedBox(width: 48, height: 48)
                      : IconButton(
                          tooltip: 'Toggle flash',
                          onPressed: () => _scannerController.toggleTorch(),
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                        ),
                ],
              ),
            ),
          ),

          // Bottom instructions + manual entry
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_cameraFailed) ...[
                      Text(
                        'Point your camera at the QR code on the pack',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _showManualEntrySheet,
                        icon: const Icon(Icons.keyboard_outlined, size: 20),
                        label: const Text(
                          'Enter Code Manually',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}