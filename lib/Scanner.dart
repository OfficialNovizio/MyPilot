import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CardScanResult {
  final String? brand; // Visa, Mastercard, Amex, etc.
  final String? last4; // "1234"
  final String? rawDetectedNumber; // for debugging ONLY (don’t store)
  CardScanResult({this.brand, this.last4, this.rawDetectedNumber});
}

class CardScanController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final isScanning = false.obs;
  final error = ''.obs;

  // Output fields you can bind to your “Add Card” form
  final brand = RxnString();
  final last4 = RxnString();
  final suggestedName = ''.obs; // e.g. "Visa •••• 1234"

  Future<void> scanCardFront() async {
    error.value = '';
    isScanning.value = true;

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (file == null) {
        isScanning.value = false;
        return;
      }

      final result = await _extractCardMetaFromImage(File(file.path));

      // IMPORTANT: Do NOT store the image. Delete it ASAP.
      try {
        await File(file.path).delete();
      } catch (_) {}

      if (result.last4 == null) {
        error.value = "Couldn’t detect a card number clearly. Try better light (no glare) or type last 4 manually.";
      } else {
        brand.value = result.brand ?? 'Card';
        last4.value = result.last4;
        suggestedName.value = "${brand.value} •••• ${last4.value}";
      }
    } catch (e) {
      error.value = "Scan failed: $e";
    } finally {
      isScanning.value = false;
    }
  }

  Future<CardScanResult> _extractCardMetaFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final allText = recognizedText.text;

      // Find candidate numbers (13–19 digits), allow spaces/hyphens
      final candidates = _findDigitCandidates(allText);

      // Pick best valid Luhn number
      String? best;
      for (final c in candidates) {
        if (_isValidCardNumber(c)) {
          best = c;
          break;
        }
      }

      if (best == null) {
        return CardScanResult();
      }

      final last4 = best.substring(best.length - 4);
      final brand = _detectBrand(best);

      return CardScanResult(
        brand: brand,
        last4: last4,
        rawDetectedNumber: best, // don’t persist this
      );
    } finally {
      await textRecognizer.close();
    }
  }

  List<String> _findDigitCandidates(String text) {
    // Pull out digit groups that might represent PAN.
    // This regex finds sequences with digits/spaces/hyphens of plausible length.
    final reg = RegExp(r'(?<!\d)(?:\d[ -]?){13,19}(?!\d)');
    final matches = reg.allMatches(text);

    final cleaned = <String>[];
    for (final m in matches) {
      final raw = m.group(0) ?? '';
      final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length >= 13 && digitsOnly.length <= 19) {
        cleaned.add(digitsOnly);
      }
    }

    // Prefer longer first (often 16), then return
    cleaned.sort((a, b) => b.length.compareTo(a.length));
    return cleaned;
  }

  bool _isValidCardNumber(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    return _luhnCheck(digits);
  }

  bool _luhnCheck(String digits) {
    int sum = 0;
    bool alternate = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String _detectBrand(String digits) {
    // Basic BIN prefix rules (not exhaustive but good enough)
    if (digits.startsWith('4')) return 'Visa';

    // Mastercard: 51–55 or 2221–2720
    final two = int.tryParse(digits.substring(0, 2)) ?? 0;
    final four = int.tryParse(digits.substring(0, 4)) ?? 0;
    if (two >= 51 && two <= 55) return 'Mastercard';
    if (four >= 2221 && four <= 2720) return 'Mastercard';

    // Amex: 34, 37
    if (digits.startsWith('34') || digits.startsWith('37')) return 'Amex';

    // Discover: 6011, 65, 644–649
    if (digits.startsWith('6011') || digits.startsWith('65')) return 'Discover';
    final three = int.tryParse(digits.substring(0, 3)) ?? 0;
    if (three >= 644 && three <= 649) return 'Discover';

    return 'Card';
  }
}

class CardScanTile extends StatelessWidget {
  CardScanTile({super.key});

  final c = Get.put(CardScanController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: c.isScanning.value ? null : c.scanCardFront,
            icon: c.isScanning.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.credit_card),
            label: Text(c.isScanning.value ? "Scanning..." : "Scan card front"),
          ),
          const SizedBox(height: 12),

          if (c.suggestedName.value.isNotEmpty) Text("Suggested: ${c.suggestedName.value}", style: const TextStyle(fontWeight: FontWeight.w600)),

          if (c.error.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(c.error.value, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 12),

          // Example: bind these into your TextEditingControllers
          if (c.last4.value != null) Text("Saved fields → Brand: ${c.brand.value}, Last4: ${c.last4.value}"),
        ],
      );
    });
  }
}
