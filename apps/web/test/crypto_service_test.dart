import 'dart:convert' show base64;
import 'dart:typed_data';

import 'package:chronowarden/services/crypto_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extract raw bytes from a [SecretKey] for equality assertions.
Future<List<int>> bytesOf(SecretKey key) => key.extractBytes();

void main() {
  group('salt', () {
    test('has the configured length and is not repeated', () {
      final a = CryptoService.generateSalt();
      final b = CryptoService.generateSalt();
      expect(a.length, CryptoService.saltLength);
      expect(b.length, CryptoService.saltLength);
      expect(a, isNot(equals(b)));
    });
  });

  group('data encryption (AES-256-GCM)', () {
    test('round-trips plaintext', () async {
      final dek = await CryptoService.generateDek();
      const plaintext = '{"date":"2026-09-23","note":"åäö / emoji 🛡️"}';

      final ciphertext = await CryptoService.encrypt(plaintext, dek);
      final decrypted = await CryptoService.decrypt(ciphertext, dek);

      expect(decrypted, plaintext);
    });

    test('uses a fresh nonce so equal plaintext yields different ciphertext',
        () async {
      final dek = await CryptoService.generateDek();
      const plaintext = 'same input';

      final c1 = await CryptoService.encrypt(plaintext, dek);
      final c2 = await CryptoService.encrypt(plaintext, dek);

      expect(c1, isNot(equals(c2)));
      expect(await CryptoService.decrypt(c1, dek), plaintext);
      expect(await CryptoService.decrypt(c2, dek), plaintext);
    });

    test('fails to decrypt with the wrong key', () async {
      final dek = await CryptoService.generateDek();
      final otherDek = await CryptoService.generateDek();
      final ciphertext = await CryptoService.encrypt('secret', dek);

      expect(
        () => CryptoService.decrypt(ciphertext, otherDek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('rejects tampered ciphertext (MAC verification)', () async {
      final dek = await CryptoService.generateDek();
      final ciphertext = await CryptoService.encrypt('do not touch', dek);

      final bytes = Uint8List.fromList(base64.decode(ciphertext));
      // Flip a bit in the encrypted payload (past the 12-byte nonce).
      bytes[bytes.length - 20] ^= 0x01;
      final tampered = base64.encode(bytes);

      expect(
        () => CryptoService.decrypt(tampered, dek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('envelope key wrap', () {
    late SecretKey dek;
    late SecretKey masterKey;

    setUpAll(() async {
      dek = await CryptoService.generateDek();
      final salt = CryptoService.generateSalt();
      masterKey = await CryptoService.deriveMasterKey('correct horse battery staple', salt);
    });

    test('unwrap(wrap(dek)) recovers the original DEK', () async {
      final wrapped = await CryptoService.wrapDekBase64(dek, masterKey);
      final unwrapped = await CryptoService.unwrapDekBase64(wrapped, masterKey);

      expect(await bytesOf(unwrapped), equals(await bytesOf(dek)));
    });

    test('a wrong passphrase cannot unwrap the DEK', () async {
      final wrapped = await CryptoService.wrapDekBase64(dek, masterKey);
      final wrongKey = await CryptoService.deriveMasterKey(
        'wrong passphrase',
        CryptoService.generateSalt(),
      );

      expect(
        () => CryptoService.unwrapDekBase64(wrapped, wrongKey),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('wrapDekWithPassphrase derives a usable envelope', () async {
      final result = await CryptoService.wrapDekWithPassphrase(dek, 'new-pass');
      expect(result.keys, containsAll(['wrapped_b64', 'salt_b64', 'iterations']));

      final newMaster = await CryptoService.deriveMasterKey(
        'new-pass',
        Uint8List.fromList(base64.decode(result['salt_b64'] as String)),
      );
      final unwrapped = await CryptoService.unwrapDekBase64(
        result['wrapped_b64'] as String,
        newMaster,
      );
      expect(await bytesOf(unwrapped), equals(await bytesOf(dek)));
      expect(result['iterations'], CryptoService.kekIterations);
    });
  });

  group('recovery phrase', () {
    test('encodes a DEK as 24 words and round-trips', () async {
      final dek = await CryptoService.generateDek();

      final phrase = await CryptoService.dekToMnemonic(dek);
      expect(phrase.split(' '), hasLength(24));

      final recovered = await CryptoService.mnemonicToDek(phrase);
      expect(await bytesOf(recovered), equals(await bytesOf(dek)));
    });

    test('round-trips across many random DEKs (guards wordlist bijection)', () async {
      // Regression: the BIP39 wordlist previously contained 19 duplicate
      // words, so ~20% of generated phrases decoded to the wrong DEK. Over
      // 300 iterations the old code failed ~66 times.
      for (var i = 0; i < 300; i++) {
        final dek = await CryptoService.generateDek();
        final phrase = await CryptoService.dekToMnemonic(dek);
        final recovered = await CryptoService.mnemonicToDek(phrase);
        expect(
          await bytesOf(recovered),
          equals(await bytesOf(dek)),
          reason: 'mnemonic round-trip failed on iteration $i',
        );
      }
    });

    test('rejects a phrase with an unknown word', () async {
      final dek = await CryptoService.generateDek();
      final words = (await CryptoService.dekToMnemonic(dek)).split(' ');
      words[0] = 'notaword';

      expect(
        () => CryptoService.mnemonicToDek(words.join(' ')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a phrase with a corrupted checksum', () async {
      final dek = await CryptoService.generateDek();
      final words = (await CryptoService.dekToMnemonic(dek)).split(' ');

      // Swap one word for a different valid word and look for a checksum
      // failure. Each candidate has a 1/256 chance of passing the 8-bit
      // checksum, so across several candidates a rejection is certain.
      var rejected = false;
      for (final candidate in ['abandon', 'ability', 'able', 'about', 'absent']) {
        if (candidate == words[0]) continue;
        final mutated = [...words]..[0] = candidate;
        try {
          await CryptoService.mnemonicToDek(mutated.join(' '));
        } on ArgumentError {
          rejected = true;
          break;
        }
      }
      expect(rejected, isTrue);
    });

    test('rejects a phrase with the wrong word count', () async {
      final dek = await CryptoService.generateDek();
      final words = (await CryptoService.dekToMnemonic(dek)).split(' ');
      final short = words.sublist(0, 23).join(' ');

      expect(
        () => CryptoService.mnemonicToDek(short),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('hashRecoveryPhrase is deterministic and phrase-specific', () {
      final h1 = CryptoService.hashRecoveryPhrase('one two three');
      final h2 = CryptoService.hashRecoveryPhrase('one two three');
      final h3 = CryptoService.hashRecoveryPhrase('three two one');

      expect(h1, h2);
      expect(h1, isNot(h3));
    });
  });
}
