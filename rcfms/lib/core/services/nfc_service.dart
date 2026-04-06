import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart' as nfc_android;
import 'package:nfc_manager/nfc_manager_ios.dart' as nfc_ios;

/// Service to handle NFC interactions
class NfcService {
  bool _isAvailable = false;

  // Simulation flag - Enable this to test on Desktop/Simulator
  static const bool _simulateOnUnsupported = true;

  /// Check if NFC is available on this device
  Future<bool> isAvailable() async {
    // If simulation is enabled and we are on an unsupported platform, return true
    if (_simulateOnUnsupported &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return true;
    }

    try {
      _isAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      _isAvailable = false;
    }
    return _isAvailable;
  }

  /// Start a session to read a single tag
  /// Returns the Tag ID (Mifare UID usually) as a hex string (e.g., "04:A2:...")
  Future<String?> scanTag({
    String instruction = 'Hold device near the NFC tag.',
  }) async {
    // Simulator Logic
    if (_simulateOnUnsupported &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await Future.delayed(const Duration(seconds: 2)); // Fake scanning delay
      // Generate random mock ID
      final random = Random();
      final bytes = List<int>.generate(4, (i) => random.nextInt(256));
      return bytes
          .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
    }

    if (!await isAvailable()) {
      throw Exception('NFC is not supported or enabled on this device.');
    }

    final completer = Completer<String?>();

    try {
      // Start Session
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            List<int>? idBytes;

            // Android: NfcTagAndroid gives generic ID access for almost all tags
            if (Platform.isAndroid) {
              try {
                final androidTag = nfc_android.NfcTagAndroid.from(tag);
                if (androidTag != null) {
                  idBytes = androidTag.id;
                }
              } catch (e) {
                print('NFC DEBUG: Error converting to Android Tag: $e');
              }
            }

            // iOS: Check specific tag types
            else if (Platform.isIOS) {
              try {
                final mifare = nfc_ios.MiFareIos.from(tag);
                if (mifare != null) {
                  idBytes = mifare.identifier;
                } else {
                  final iso7816 = nfc_ios.Iso7816Ios.from(tag);
                  if (iso7816 != null) {
                    idBytes = iso7816.identifier;
                  } else {
                    final iso15693 = nfc_ios.Iso15693Ios.from(tag);
                    if (iso15693 != null) {
                      idBytes = iso15693.identifier;
                    }
                  }
                }
              } catch (e) {
                print('NFC DEBUG: Error converting to iOS Tag: $e');
              }
            }

            // Fallback: If platform specific helper failed, try to treat data as Map IF it is one
            if (idBytes == null) {
              try {
                final data = tag.data;
                // Check if data is actually a Map before accessing
                if (data is Map<String, dynamic>) {
                  // Try generic extraction (e.g. for mifareclassic key if present)
                  // But usually platform helpers cover it.
                } else {
                  print(
                      'NFC DEBUG: tag.data is not a Map! It is: ${data.runtimeType}');
                }
              } catch (e) {
                print('NFC DEBUG: Could not access tag.data: $e');
              }
            }

            if (idBytes != null) {
              final idString = idBytes
                  .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join(':');

              // Delay stopping the session to prevent Android system "New tag scanned" popup
              await Future.delayed(const Duration(milliseconds: 1000));

              await NfcManager.instance.stopSession();
              if (!completer.isCompleted) {
                completer.complete(idString);
              }
            } else {
              await NfcManager.instance.stopSession();
              if (!completer.isCompleted) {
                // Return null instead of error to allow retry without crash
                print('NFC DEBUG: Could not read Tag ID');
                completer.complete(null);
              }
            }
          } catch (e) {
            print('NFC DEBUG: Error exploring tag: $e');
            await NfcManager.instance.stopSession();

            // Send null on TagPigeon error to suppress UI crash
            if (e.toString().contains('TagPigeon')) {
              if (!completer.isCompleted) completer.complete(null);
            } else {
              if (!completer.isCompleted) completer.completeError(e);
            }
          }
        },
      );
    } catch (e) {
      return null;
    }

    return completer.future;
  }

  /// Stop any active session
  Future<void> stopSession() async {
    // Simulator Logic
    if (_simulateOnUnsupported &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    if (await isAvailable()) {
      try {
        await NfcManager.instance.stopSession();
      } catch (e) {
        // Ignore
      }
    }
  }
}
