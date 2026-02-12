// ignore_for_file: unnecessary_cast

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:pointycastle/export.dart';

/// ========================
/// HEX ↔ BYTES HELPERS
/// ========================

Uint8List hexToBytes(String hex) {
  if (hex.length % 2 != 0) {
    throw FormatException("Invalid hex length");
  }

  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < hex.length; i += 2) {
    result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return result;
}

String bytesToHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    buffer.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// ========================
/// DEVICE KEYS MODEL
/// ========================

class DeviceKeys {
  final Uint8List privateKey;
  final Uint8List publicKey;

  DeviceKeys({
    required this.privateKey,
    required this.publicKey,
  });
}

/// ========================
/// GET OR CREATE DEVICE KEYS
/// ========================

Future<DeviceKeys> getOrCreateDeviceKeys() async {
  final box = await Hive.openBox('device_keys');

  final Uint8List? storedPrivate = box.get('privateKey');
  final Uint8List? storedPublic = box.get('publicKey');

  if (storedPrivate != null && storedPublic != null) {
    return DeviceKeys(
      privateKey: storedPrivate,
      publicKey: storedPublic,
    );
  }

  // 🔐 Generate ECDSA P-256 keypair
  final domainParams = ECDomainParameters('secp256r1');
  final keyParams = ECKeyGeneratorParameters(domainParams);

  final secureRandom = FortunaRandom()
    ..seed(
      KeyParameter(
        Uint8List.fromList(
          List<int>.generate(32, (_) => Random.secure().nextInt(256)),
        ),
      ),
    );

  final generator = ECKeyGenerator()
    ..init(ParametersWithRandom(keyParams, secureRandom));

  final pair = generator.generateKeyPair();

  // ✅ CAST IS REQUIRED
  final ECPrivateKey privateKey = pair.privateKey as ECPrivateKey;
  final ECPublicKey publicKey = pair.publicKey as ECPublicKey;

  /// Private key (d) → 32 bytes
  final privHex = privateKey.d!.toRadixString(16).padLeft(64, '0');
  final privateKeyBytes = hexToBytes(privHex);

  /// Public key → uncompressed (04 + X + Y)
  final publicKeyBytes = Uint8List.fromList(
    publicKey.Q!.getEncoded(false),
  );

  await box.put('privateKey', privateKeyBytes);
  await box.put('publicKey', publicKeyBytes);

  return DeviceKeys(
    privateKey: privateKeyBytes,
    publicKey: publicKeyBytes,
  );
}


Map<String, dynamic> ecPublicKeyToJwk(Uint8List publicKeyBytes) {
  // publicKeyBytes = 65 bytes (04 + X + Y)
  if (publicKeyBytes.length != 65 || publicKeyBytes[0] != 0x04) {
    throw Exception('Invalid uncompressed EC public key');
  }

  final x = publicKeyBytes.sublist(1, 33);
  final y = publicKeyBytes.sublist(33, 65);

  return {
    "kty": "EC",
    "crv": "P-256",
    "x": base64UrlNoPadding(x),
    "y": base64UrlNoPadding(y),
    "ext": true,
    "key_ops": ["verify"],
  };
}


String base64UrlNoPadding(Uint8List bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// ========================
/// SIGN MESSAGE (HEX OUTPUT)
/// ========================

Future<String> signWithPrivateKey(
  Uint8List privateKeyBytes,
  String message,
) async {
  final domainParams = ECDomainParameters('secp256r1');

  // Rebuild private key (same as Web importKey)
  final d = BigInt.parse(bytesToHex(privateKeyBytes), radix: 16);
  final privateKey = ECPrivateKey(d, domainParams);

  // 🔥 Deterministic ECDSA (RFC 6979) — NO SecureRandom
  final signer = ECDSASigner(
    SHA256Digest(),
    HMac(SHA256Digest(), 64),
  );

  signer.init(
    true,
    PrivateKeyParameter<ECPrivateKey>(privateKey),
  );

  final sig = signer.generateSignature(
    Uint8List.fromList(utf8.encode(message)),
  ) as ECSignature;

  // r + s → HEX (matches Web ArrayBuffer → hex)
  final r = sig.r.toRadixString(16).padLeft(64, '0');
  final s = sig.s.toRadixString(16).padLeft(64, '0');

  return r + s;
}

