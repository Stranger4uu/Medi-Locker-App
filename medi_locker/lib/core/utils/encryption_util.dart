import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// AES-256 file encryption utility.
///
/// How it works:
/// 1. A 32-byte key is derived from the user's UID (padded/hashed).
/// 2. A random 16-byte IV is generated per file.
/// 3. The IV is prepended to the encrypted bytes.
/// 4. The decrypted bytes are recovered by splitting IV + ciphertext.
///
/// The encrypted file is stored in Firebase Storage.
/// Only the same user (same UID → same key) can decrypt their own files.
class EncryptionUtil {
  EncryptionUtil._();

  /// Derive a 32-byte AES key from the Firebase user UID.
  /// We pad the UID to 32 bytes so it is always a valid AES-256 key.
  static enc.Key _keyFromUid(String uid) {
    final padded = uid.padRight(32, '0').substring(0, 32);
    return enc.Key.fromUtf8(padded);
  }

  /// Encrypt [inputFile] and write the result to [outputFile].
  /// Returns the output file.
  static Future<File> encryptFile(File inputFile, File outputFile) async {
    return compute(_encryptIsolate, _EncryptArgs(
      inputPath: inputFile.path,
      outputPath: outputFile.path,
      uid: FirebaseAuth.instance.currentUser!.uid,
    ));
  }

  /// Decrypt [inputFile] (encrypted) and write plaintext to [outputFile].
  static Future<File> decryptFile(File inputFile, File outputFile) async {
    return compute(_decryptIsolate, _EncryptArgs(
      inputPath: inputFile.path,
      outputPath: outputFile.path,
      uid: FirebaseAuth.instance.currentUser!.uid,
    ));
  }

  /// Encrypt raw bytes and return encrypted bytes (IV prepended).
  static Uint8List encryptBytes(Uint8List bytes, String uid) {
    final key = _keyFromUid(uid);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    // Prepend IV to ciphertext
    final result = Uint8List(16 + encrypted.bytes.length);
    result.setRange(0, 16, iv.bytes);
    result.setRange(16, result.length, encrypted.bytes);
    return result;
  }

  /// Decrypt bytes (IV prepended). Returns plaintext bytes.
  static Uint8List decryptBytes(Uint8List encryptedWithIv, String uid) {
    final key = _keyFromUid(uid);
    final iv = enc.IV(Uint8List.fromList(encryptedWithIv.sublist(0, 16)));
    final ciphertext = encryptedWithIv.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(ciphertext)), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}

class _EncryptArgs {
  final String inputPath;
  final String outputPath;
  final String uid;
  const _EncryptArgs(
      {required this.inputPath,
      required this.outputPath,
      required this.uid});
}

File _encryptIsolate(_EncryptArgs args) {
  final inputBytes = File(args.inputPath).readAsBytesSync();
  final encrypted = EncryptionUtil.encryptBytes(inputBytes, args.uid);
  final outFile = File(args.outputPath);
  outFile.writeAsBytesSync(encrypted);
  return outFile;
}

File _decryptIsolate(_EncryptArgs args) {
  final encryptedBytes = File(args.inputPath).readAsBytesSync();
  final decrypted = EncryptionUtil.decryptBytes(encryptedBytes, args.uid);
  final outFile = File(args.outputPath);
  outFile.writeAsBytesSync(decrypted);
  return outFile;
}
