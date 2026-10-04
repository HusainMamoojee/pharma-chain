import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StaffScanScreen extends StatefulWidget {
  const StaffScanScreen({super.key});

  @override
  State<StaffScanScreen> createState() => _StaffScanScreenState();
}

class _StaffScanScreenState extends State<StaffScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();
    _goToCustody(code);
  }

  void _handleManualSubmit() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    _goToCustody(code);
  }

  void _goToCustody(String code) {
    context.pushReplacement('/custody-transfer', extra: code);
  }

  void _showManualEntrySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                Text('Enter Batch Code', style: AppTextStyles.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  'Type the batch or carton code manually',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _manualCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. BATCH-4521-ZA',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleManualSubmit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: AppColors.neutral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Log Batch'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.tertiary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Text('Scan Package', style: AppTextStyles.label.copyWith(color: Colors.white)),
                  IconButton(
                    onPressed: () => _scannerController.toggleTorch(),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Align the carton GS1 DataMatrix or tamper seal within the frame',
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _showManualEntrySheet,
                      child: Text(
                        'Enter Code Manually',
                        style: AppTextStyles.label.copyWith(color: AppColors.tertiary),
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
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}