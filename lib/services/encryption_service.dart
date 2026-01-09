import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptionService {
  // Use a fixed 16-byte IV (Initialization Vector)
  static final _iv = encrypt.IV(Uint8List(16));

  // Derives a 32-byte key from the chat room ID
  static encrypt.Key _getKey(String roomId) {
    final bytes = utf8.encode(roomId);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Encrypts text using AES-SIC (CCR) mode
  static String encryptMessage(String plainText, String roomId) {
    if (plainText.isEmpty) return plainText;
    try {
      final key = _getKey(roomId);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.sic),
      );
      return encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      print("Encryption Error: $e");
      return plainText;
    }
  }

  // Decrypts text
  static String decryptMessage(String text, String roomId) {
    if (text.isEmpty) return text;

    // Fast check for Base64
    try {
      base64.decode(text);
    } catch (e) {
      return text;
    }

    try {
      final key = _getKey(roomId);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.sic),
      );
      return encrypter.decrypt64(text, iv: _iv);
    } catch (e) {
      print("Decryption Error: $e");
      return text;
    }
  }
}
