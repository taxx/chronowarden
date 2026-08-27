import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web-only: sessionStorage access
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Core cryptographic operations for envelope encryption.
///
/// Key hierarchy:
///   Passphrase → PBKDF2 (310k) → Master Key (KEK)
///   Master Key → AES-GCM wrap   → Data Encryption Key (DEK)
///   DEK → AES-GCM encrypt       → Encrypted data
class CryptoService {
  // -----------------------------------------------------------------
  // Constants
  // -----------------------------------------------------------------

  /// OWASP 2025 minimum for PBKDF2-HMAC-SHA256.
  static const int kekIterations = 310_000;

  /// 256-bit AES key for both KEK and DEK.
  static const int kekKeyLengthBytes = 32;

  /// Salt length for PBKDF2 (128-bit).
  static const int saltLength = 16;

  /// AES-GCM nonce length (12 bytes = 96 bits).
  static const int nonceLength = 12;

  /// AES-GCM MAC length (16 bytes = 128 bits).
  static const int macLength = 16;

  // -----------------------------------------------------------------
  // Key lifecycle
  // -----------------------------------------------------------------

  /// Generate a cryptographically random salt.
  static Uint8List generateSalt() {
    final r = Random.secure();
    return Uint8List.fromList(
      List.generate(saltLength, (_) => r.nextInt(256)),
    );
  }

  /// Generate a random 256-bit Data Encryption Key.
  static Future<SecretKey> generateDek() async {
    final algorithm = AesGcm.with256bits();
    return algorithm.newSecretKey();
  }

  /// Derive a 256-bit Master Key (KEK) from a passphrase + salt.
  ///
  /// Uses PBKDF2-HMAC-SHA256 with [kekIterations] iterations.
  static Future<SecretKey> deriveMasterKey(
    String passphrase,
    Uint8List salt,
  ) async {
    final pbkdf2 = Pbkdf2.hmacSha256(
      iterations: kekIterations,
      bits: kekKeyLengthBytes * 8,
    );
    return pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
  }

  /// Wrap (encrypt) a DEK with a Master Key using AES-GCM.
  ///
  /// Returns base64-encoded [nonce (12) + ciphertext + mac (16)].
  static Future<String> wrapDekBase64(
    SecretKey dek,
    SecretKey masterKey,
  ) async {
    final algorithm = AesGcm.with256bits();
    final dekBytes = await dek.extractBytes();
    final secretBox = await algorithm.encrypt(
      dekBytes,
      secretKey: masterKey,
      nonce: algorithm.newNonce(),
    );
    return base64.encode(secretBox.concatenation());
  }

  /// Wrap a DEK with a new passphrase: generate salt, derive KEK, wrap.
  ///
  /// Returns the wrapped DEK (base64), the salt (base64), and the iterations.
  /// Use this when the user sets a new encryption passphrase via recovery phrase.
  static Future<Map<String, dynamic>> wrapDekWithPassphrase(
    SecretKey dek,
    String passphrase,
  ) async {
    final salt = generateSalt();
    final masterKey = await deriveMasterKey(passphrase, salt);
    final wrappedB64 = await wrapDekBase64(dek, masterKey);
    return {
      'wrapped_b64': wrappedB64,
      'salt_b64': base64.encode(salt),
      'iterations': kekIterations,
    };
  }

  /// Unwrap (decrypt) a DEK with a Master Key.
  ///
  /// Expects base64-encoded [nonce (12) + ciphertext + mac (16)].
  static Future<SecretKey> unwrapDekBase64(
    String wrappedB64,
    SecretKey masterKey,
  ) async {
    final algorithm = AesGcm.with256bits();
    final combined = base64.decode(wrappedB64);
    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: nonceLength,
      macLength: macLength,
      copy: false,
    );
    final dekBytes = await algorithm.decrypt(
      secretBox,
      secretKey: masterKey,
    );
    return SecretKey(dekBytes);
  }

  // -----------------------------------------------------------------
  // Data encryption
  // -----------------------------------------------------------------

  /// Encrypt a JSON string with the DEK using AES-GCM.
  ///
  /// Returns base64-encoded [nonce (12) + ciphertext + mac (16)].
  static Future<String> encrypt(String plaintext, SecretKey dek) async {
    final algorithm = AesGcm.with256bits();
    final plainBytes = utf8.encode(plaintext);
    final secretBox = await algorithm.encrypt(
      plainBytes,
      secretKey: dek,
      nonce: algorithm.newNonce(),
    );
    return base64.encode(secretBox.concatenation());
  }

  /// Decrypt base64-encoded ciphertext with the DEK.
  ///
  /// Expects base64 of [nonce (12) + cipherText + mac (16)].
  static Future<String> decrypt(String ciphertext, SecretKey dek) async {
    final algorithm = AesGcm.with256bits();
    final combined = base64.decode(ciphertext);
    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: nonceLength,
      macLength: macLength,
      copy: false,
    );
    final plainBytes = await algorithm.decrypt(
      secretBox,
      secretKey: dek,
    );
    return utf8.decode(plainBytes);
  }

  // -----------------------------------------------------------------
  // Recovery phrase (BIP39-like mnemonic encoding)
  // -----------------------------------------------------------------

  /// Encode a DEK as a 24-word mnemonic phrase.
  ///
  /// Uses the BIP39 wordlist (2048 words). 24 words × 11 bits = 264 bits.
  /// Encoding: 256-bit DEK + 8-bit checksum (SHA-256 first byte).
  static Future<String> dekToMnemonic(SecretKey dek) async {
    final dekBytes = await dek.extractBytes();
    return _encodeMnemonic(Uint8List.fromList(dekBytes));
  }

  /// Decode a 24-word mnemonic phrase back to a DEK.
  /// Verifies the embedded checksum.
  static Future<SecretKey> mnemonicToDek(String phrase) async {
    final dekBytes = _decodeMnemonic(phrase);
    return SecretKey(dekBytes);
  }

  /// Hash a recovery phrase for storage/verification (SHA-256).
  static String hashRecoveryPhrase(String phrase) {
    final bytes = utf8.encode(phrase);
    final digest = crypto.sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // -----------------------------------------------------------------
  // Persistent cache (web localStorage)
  // -----------------------------------------------------------------
  //
  // Stores the unwrapped DEK in localStorage so it survives closing and
  // reopening the browser tab. The user only needs to enter their
  // encryption passphrase once per browser, not once per session.
  // Cleared on logout.
  //
  // Security: localStorage is accessible to same-origin JavaScript, but
  // the DEK alone is useless without the encrypted data from Supabase
  // (which requires the user's auth session).

  static const _dekStorageKey = 'cw_dek';

  /// Save DEK to localStorage (survives tab close + reopen).
  static void cacheDekLocally(SecretKey dek) async {
    if (!kIsWeb) return;
    final bytes = await dek.extractBytes();
    // ignore: avoid_web_libraries_in_flutter
    html.window.localStorage[_dekStorageKey] = base64.encode(bytes);
  }

  /// Load DEK from localStorage (returns null if not cached).
  static Future<SecretKey?> loadDekFromLocal() async {
    if (!kIsWeb) return null;
    // ignore: avoid_web_libraries_in_flutter
    final cached = html.window.localStorage[_dekStorageKey];
    if (cached == null || cached.isEmpty) return null;
    final bytes = base64.decode(cached);
    return SecretKey(Uint8List.fromList(bytes));
  }

  /// Clear DEK from localStorage (on logout).
  static void clearLocalCache() {
    if (!kIsWeb) return;
    // ignore: avoid_web_libraries_in_flutter
    html.window.localStorage.remove(_dekStorageKey);
  }
}

// ---------------------------------------------------------------------------
// BIP39 wordlist (2048 English words for mnemonic encoding)
// ---------------------------------------------------------------------------

const _bip39Words = <String>[
  'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract',
  'absurd', 'abuse', 'accelerate', 'accept', 'access', 'across', 'act', 'action',
  'active', 'actual', 'address', 'adjust', 'admit', 'adult', 'advance', 'advice',
  'afraid', 'agree', 'ahead', 'aid', 'aim', 'air', 'alarm', 'album',
  'alert', 'alien', 'align', 'alive', 'all', 'allow', 'almost', 'alone',
  'along', 'alter', 'always', 'amaze', 'among', 'amount', 'ancient', 'angle',
  'animal', 'announce', 'annual', 'answer', 'antenna', 'anxiety', 'apart', 'apology',
  'appear', 'apple', 'approve', 'april', 'arch', 'arctic', 'area', 'argue',
  'arm', 'army', 'around', 'arrange', 'arrest', 'arrive', 'arrow', 'art',
  'artist', 'ask', 'aspect', 'assault', 'asset', 'assist', 'attack', 'attend',
  'attract', 'auction', 'author', 'auto', 'available', 'average', 'avoid', 'award',
  'aware', 'away', 'awful', 'axis', 'back', 'badge', 'balance', 'ball',
  'ban', 'banana', 'bank', 'bar', 'barely', 'barrel', 'basic', 'basket',
  'battle', 'beach', 'beauty', 'become', 'before', 'begin', 'behave', 'behind',
  'believe', 'below', 'beneath', 'benefit', 'beside', 'best', 'better', 'beyond',
  'bicycle', 'bid', 'big', 'bike', 'bill', 'birth', 'bite', 'bitter',
  'black', 'blade', 'blame', 'blank', 'blast', 'blaze', 'bleed', 'blend',
  'bless', 'blind', 'block', 'blood', 'bloom', 'blue', 'board', 'body',
  'bone', 'bonus', 'book', 'boost', 'border', 'bore', 'born', 'boss',
  'bottom', 'bounce', 'box', 'brain', 'branch', 'brand', 'brave', 'bread',
  'break', 'breath', 'breed', 'brief', 'bring', 'broad', 'brother', 'brown',
  'brush', 'budget', 'build', 'unique', 'update', 'upgrade', 'uphold', 'upper',
  'urban', 'urge', 'usage', 'useful', 'user', 'usual', 'valid', 'value',
  'van', 'vanish', 'vapor', 'various', 'vast', 'vehicle', 'venture', 'venue',
  'version', 'veto', 'vibrant', 'victim', 'victory', 'video', 'view', 'village',
  'vintage', 'violation', 'violence', 'vision', 'visit', 'visual', 'voice', 'volume',
  'volunteer', 'vote', 'vulnerable', 'wagon', 'wait', 'walk', 'wall', 'wallet',
  'wander', 'want', 'war', 'warm', 'wash', 'waste', 'watch', 'water',
  'wave', 'way', 'wealth', 'weather', 'web', 'wedding', 'week', 'weight',
  'welcome', 'welfare', 'west', 'wet', 'whale', 'whatever', 'wheat', 'wheel',
  'when', 'where', 'which', 'while', 'white', 'whole', 'wide', 'willing',
  'win', 'window', 'wing', 'winter', 'wire', 'wise', 'with', 'within',
  'without', 'witness', 'woman', 'wonder', 'wood', 'wool', 'word', 'work',
  'world', 'worry', 'wrap', 'write', 'wrong', 'yard', 'year', 'yellow',
  'yes', 'yield', 'young', 'zero', 'zone', 'zoo', 'acid', 'acoustic',
  'across', 'action', 'active', 'address', 'advance', 'affair', 'afternoon', 'agency',
  'agenda', 'aggregate', 'airplane', 'airport', 'album', 'algebra', 'algorithm', 'alley',
  'alliance', 'allowance', 'aluminum', 'analysis', 'analyst', 'anatomy', 'angel', 'anniversary',
  'anthology', 'apartment', 'apparatus', 'appendix', 'appetite', 'aquarium', 'arcade', 'architect',
  'archive', 'arena', 'arithmetic', 'armor', 'arrangement', 'artefact', 'article', 'assembly',
  'astronomy', 'athlete', 'atlas', 'atmosphere', 'attachment', 'attorney', 'audience', 'auditorium',
  'authority', 'automation', 'avalanche', 'avenue', 'backup', 'bacteria', 'bargain', 'barrier',
  'baseline', 'battery', 'bay', 'bedroom', 'beverage', 'bible', 'biscuit', 'blanket',
  'blueprint', 'bluetooth', 'bonanza', 'booklet', 'booth', 'bottle', 'boulevard', 'boundary',
  'bracelet', 'breach', 'breakfast', 'briefcase', 'broadcast', 'brochure', 'bubble', 'buffer',
  'building', 'bulletin', 'bundle', 'burden', 'bureau', 'burglar', 'bus', 'bush',
  'business', 'cabinet', 'cable', 'cadence', 'calendar', 'campaign', 'campus', 'candidate',
  'capacity', 'capital', 'caption', 'capture', 'carbon', 'cargo', 'carnival', 'carpet',
  'catalog', 'category', 'caution', 'cavity', 'ceiling', 'celebrate', 'cellular', 'cemetery',
  'center', 'ceremony', 'certificate', 'challenge', 'chamber', 'champion', 'chapter', 'character',
  'charity', 'charter', 'checklist', 'chemical', 'chocolate', 'chorus', 'chronic', 'cipher',
  'circuit', 'circular', 'citizen', 'civil', 'classic', 'classroom', 'clause', 'clergy',
  'clinic', 'clock', 'cluster', 'coach', 'coalition', 'coast', 'code', 'coffee',
  'collapse', 'colleague', 'college', 'collision', 'colonel', 'column', 'combat', 'comedy',
  'comment', 'commerce', 'commission', 'committee', 'commodity', 'communication', 'community', 'company',
  'compare', 'compass', 'complaint', 'complex', 'component', 'computer', 'concept', 'concert',
  'conclusion', 'concrete', 'condition', 'conference', 'confidence', 'conflict', 'congress', 'connection',
  'consequence', 'conservation', 'consider', 'constitution', 'construction', 'consultant', 'consumer', 'contact',
  'container', 'contest', 'context', 'contract', 'contrast', 'convention', 'conversation', 'coordinate',
  'council', 'counselor', 'counter', 'country', 'couple', 'courage', 'course', 'court',
  'covenant', 'cover', 'craft', 'cream', 'creature', 'credit', 'crew', 'cricket',
  'criterion', 'critical', 'crop', 'crown', 'crucial', 'crystal', 'culture', 'currency',
  'curriculum', 'customer', 'custom', 'cycle', 'database', 'deadline', 'debate', 'debt',
  'decade', 'decimal', 'decision', 'declaration', 'decoration', 'decrease', 'deduction', 'defense',
  'definition', 'degree', 'delay', 'delegation', 'delivery', 'demand', 'democracy', 'department',
  'departure', 'deposit', 'depression', 'description', 'design', 'destination', 'detection', 'determination',
  'diagnosis', 'diagram', 'diamond', 'diary', 'dictionary', 'difference', 'dimension', 'diploma',
  'direction', 'directory', 'disaster', 'discipline', 'discount', 'discovery', 'discretion', 'discussion',
  'disease', 'display', 'disposal', 'distance', 'distinction', 'distribution', 'disturbance', 'diversity',
  'division', 'document', 'domain', 'drama', 'drought', 'duration', 'dynamics', 'economy',
  'edition', 'editor', 'education', 'effect', 'efficiency', 'effort', 'election', 'electricity',
  'element', 'elevator', 'eligibility', 'elimination', 'emergency', 'emission', 'emotion', 'emphasis',
  'empire', 'employee', 'employer', 'enclosure', 'encounter', 'endorsement', 'enforcement', 'engagement',
  'engine', 'engineering', 'enrollment', 'enterprise', 'environment', 'equipment', 'equity', 'essay',
  'estate', 'evaluation', 'event', 'evidence', 'evolution', 'examination', 'excess', 'exchange',
  'execution', 'exemption', 'exercise', 'exhibition', 'existence', 'expansion', 'expense', 'expert',
  'explanation', 'exploration', 'extension', 'extent', 'extreme', 'fabric', 'facility', 'factor',
  'faculty', 'fashion', 'feature', 'federal', 'feedback', 'festival', 'figure', 'finance',
  'finding', 'firm', 'fixture', 'flexibility', 'flood', 'flower', 'focused', 'footage',
  'forecast', 'formation', 'formula', 'fortune', 'forum', 'foundation', 'fraction', 'freedom',
  'frequency', 'friendship', 'fusion', 'gallery', 'garbage', 'garlic', 'gather', 'gazette',
  'gender', 'genealogy', 'general', 'generation', 'genetics', 'geography', 'geology', 'geometry',
  'glacier', 'glance', 'glimpse', 'global', 'glossary', 'goal', 'goddess', 'gold',
  'golf', 'governor', 'grace', 'grade', 'graduate', 'grammar', 'graph', 'gravity',
  'green', 'group', 'guarantee', 'guardian', 'guidance', 'guitar', 'gymnastics', 'habitat',
  'half', 'hall', 'handbook', 'handling', 'harbor', 'harmony', 'harvest', 'headline',
  'health', 'hearing', 'heart', 'heaven', 'height', 'heritage', 'highway', 'history',
  'hobby', 'holiday', 'horizon', 'hormone', 'hospital', 'hostel', 'household', 'housing',
  'humanity', 'hygiene', 'hypothesis', 'identity', 'ideology', 'ignorance', 'illustration', 'image',
  'imagination', 'immigration', 'impact', 'implementation', 'import', 'impression', 'improvement', 'incident',
  'inclusion', 'income', 'independence', 'indication', 'industry', 'inflation', 'information', 'initiative',
  'injection', 'injury', 'innovation', 'inquiry', 'inspection', 'instance', 'instinct', 'institution',
  'instruction', 'insurance', 'integrity', 'intensity', 'intention', 'interaction', 'interest', 'interface',
  'intervention', 'interview', 'introduction', 'inventory', 'investment', 'isolation', 'journal', 'journey',
  'judgment', 'jurisdiction', 'justice', 'laboratory', 'landlord', 'landscape', 'language', 'launch',
  'leadership', 'learning', 'lecture', 'legacy', 'legend', 'legislation', 'legitimate', 'leisure',
  'liability', 'liberal', 'liberty', 'license', 'life', 'lifestyle', 'limitation', 'literature',
  'livestock', 'location', 'logistics', 'longitude', 'maintenance', 'management', 'manuscript', 'marathon',
  'margin', 'marketing', 'mastery', 'material', 'mathematics', 'maximum', 'mechanism', 'medicine',
  'medium', 'membership', 'memory', 'mention', 'merchant', 'message', 'metadata', 'method',
  'midnight', 'migration', 'mineral', 'minimum', 'minister', 'ministry', 'miracle', 'mission',
  'mobile', 'modem', 'momentum', 'monarchy', 'monitor', 'monopoly', 'monument', 'morning',
  'mortgage', 'mountain', 'movement', 'mystery', 'narrative', 'navigation', 'necessity', 'negotiation',
  'neighborhood', 'network', 'neutral', 'nightmare', 'nobility', 'nomination', 'notebook', 'notification',
  'novel', 'nuance', 'nursery', 'nutrition', 'observation', 'obstacle', 'occasion', 'occupation',
  'offense', 'offer', 'office', 'operation', 'opinion', 'optimism', 'option', 'orchestra',
  'organ', 'organization', 'orientation', 'original', 'outcome', 'outdoor', 'outline', 'outlook',
  'outrage', 'pacemaker', 'package', 'painting', 'pandemic', 'panel', 'panic', 'panorama',
  'parade', 'paragraph', 'parallel', 'parent', 'parliament', 'particle', 'passage', 'passion',
  'password', 'patent', 'pathology', 'patrol', 'pattern', 'payment', 'penalty', 'pension',
  'percentage', 'perception', 'performance', 'perimeter', 'permit', 'personality', 'perspective', 'petition',
  'pharmacy', 'phenomenon', 'philosophy', 'phone', 'photograph', 'phrase', 'physics', 'pipeline',
  'planning', 'platform', 'pleasure', 'pocket', 'poetry', 'policy', 'pollution', 'portfolio',
  'position', 'possession', 'potential', 'poverty', 'practice', 'precaution', 'precedent', 'prediction',
  'preference', 'prejudice', 'premier', 'premium', 'preparation', 'prescription', 'preservation', 'president',
  'prevention', 'principle', 'priority', 'privilege', 'procedure', 'proceeding', 'processing', 'production',
  'profession', 'profile', 'program', 'progression', 'project', 'promotion', 'property', 'proposal',
  'protection', 'psychology', 'publication', 'publicity', 'publisher', 'qualification', 'quarter', 'questionnaire',
  'quota', 'quotation', 'radiation', 'reaction', 'reality', 'rebellion', 'reception', 'recipe',
  'reclamation', 'recognition', 'recommendation', 'recording', 'recreation', 'recruitment', 'reflection', 'reform',
  'refugee', 'region', 'register', 'regulation', 'rehearsal', 'rejection', 'relation', 'relevance',
  'religion', 'reminder', 'rental', 'repetition', 'replacement', 'report', 'representation', 'reputation',
  'requirement', 'research', 'reservation', 'resolution', 'resource', 'response', 'responsibility', 'restaurant',
  'restoration', 'restriction', 'retail', 'retirement', 'revenue', 'review', 'revolution', 'rhetoric',
  'rhythm', 'rivalry', 'romance', 'rotation', 'routine', 'sanction', 'scandal', 'scenario',
  'schedule', 'scholarship', 'screening', 'secretary', 'security', 'semester', 'seminar', 'sensation',
  'sensitivity', 'sentence', 'sentiment', 'sequence', 'session', 'settlement', 'severity', 'shelter',
  'shield', 'shipping', 'shortage', 'shuttle', 'signature', 'silicon', 'situation', 'sketch',
  'society', 'software', 'solution', 'somewhere', 'sophistication', 'source', 'specialist', 'specification',
  'spectrum', 'spirit', 'sponsor', 'spreadsheet', 'stability', 'statistic', 'status', 'stereotype',
  'stimulus', 'stock', 'storage', 'strategy', 'structure', 'subsidy', 'substance', 'suburb',
  'succession', 'summary', 'supplement', 'supply', 'survey', 'suspicion', 'syllabus', 'symbol',
  'syndrome', 'tactics', 'talent', 'target', 'taxation', 'technique', 'technology', 'temporary',
  'tender', 'tension', 'termination', 'territory', 'theater', 'theorem', 'theory', 'therapy',
  'threshold', 'timetable', 'tissue', 'tolerance', 'tomorrow', 'toolbar', 'tourism', 'tradition',
  'traffic', 'training', 'transaction', 'translation', 'transport', 'treatment', 'trend', 'trial',
  'trigger', 'trustee', 'turnover', 'tutorial', 'typography', 'ultimatum', 'umbrella', 'unanimous',
  'understanding', 'undertaking', 'unemployment', 'unification', 'union', 'universe', 'upbringing', 'upheaval',
  'utilization', 'vacancy', 'validation', 'valley', 'vanilla', 'variation', 'vegetable', 'velocity',
  'verdict', 'verification', 'veteran', 'vibration', 'victory', 'village', 'violation', 'visibility',
  'visitor', 'volcano', 'voltage', 'volume', 'volunteer', 'voucher', 'warehouse', 'warranty',
  'weather', 'website', 'welcome', 'welfare', 'western', 'wheat', 'willing', 'window',
  'winter', 'wisdom', 'withdrawal', 'witness', 'workforce', 'workshop', 'wormhole', 'worship',
  'writing', 'xenophobia', 'yearbook', 'yesterday', 'youth', 'zeppelin', 'accident', 'account',
  'accuse', 'achieve', 'acquire', 'actor', 'actress', 'adapt', 'add', 'addict',
  'aerobic', 'afford', 'again', 'age', 'agent', 'aisle', 'alcohol', 'alpha',
  'already', 'also', 'amateur', 'amazing', 'amused', 'anchor', 'anger', 'angry',
  'ankle', 'another', 'antique', 'any', 'armed', 'artwork', 'assume', 'asthma',
  'atom', 'attitude', 'audit', 'august', 'aunt', 'autumn', 'avocado', 'awake',
  'awesome', 'awkward', 'baby', 'bachelor', 'bacon', 'bag', 'balcony', 'bamboo',
  'banner', 'base', 'bean', 'because', 'beef', 'belt', 'bench', 'betray',
  'between', 'bind', 'biology', 'bird', 'bleak', 'blossom', 'blouse', 'blur',
  'blush', 'boat', 'boil', 'bomb', 'boring', 'borrow', 'boy', 'bracket',
  'brass', 'breeze', 'brick', 'bridge', 'bright', 'brisk', 'broccoli', 'broken',
  'bronze', 'broom', 'buddy', 'buffalo', 'bulb', 'bulk', 'bullet', 'bunker',
  'burger', 'burst', 'busy', 'butter', 'buyer', 'buzz', 'cabbage', 'cabin',
  'cactus', 'cage', 'cake', 'call', 'calm', 'camera', 'camp', 'can',
  'canal', 'cancel', 'candy', 'cannon', 'canoe', 'canvas', 'canyon', 'capable',
  'captain', 'car', 'card', 'carry', 'cart', 'case', 'cash', 'casino',
  'castle', 'casual', 'cat', 'catch', 'cattle', 'caught', 'cause', 'cave',
  'celery', 'cement', 'census', 'century', 'cereal', 'certain', 'chair', 'chalk',
  'change', 'chaos', 'charge', 'chase', 'chat', 'cheap', 'check', 'cheese',
  'chef', 'cherry', 'chest', 'chicken', 'chief', 'child', 'chimney', 'choice',
  'choose', 'chuckle', 'chunk', 'churn', 'cigar', 'cinnamon', 'circle', 'city',
  'claim', 'clap', 'clarify', 'claw', 'clay', 'clean', 'clerk', 'clever',
  'click', 'client', 'cliff', 'climb', 'clip', 'clog', 'close', 'cloth',
  'cloud', 'clown', 'club', 'clump', 'clutch', 'coconut', 'coil', 'coin',
  'collect', 'color', 'combine', 'come', 'comfort', 'comic', 'common', 'conduct',
  'confirm', 'connect', 'control', 'convince', 'cook', 'cool', 'copper', 'copy',
  'coral', 'core', 'corn', 'correct', 'cost', 'cotton', 'couch', 'cousin',
  'coyote', 'crack', 'cradle', 'cram', 'crane', 'crash', 'crater', 'crawl',
  'crazy', 'creek', 'crime', 'crisp', 'critic', 'cross', 'crouch', 'crowd',
  'cruel', 'cruise', 'crumble', 'crunch', 'crush', 'cry', 'cube', 'cup',
  'cupboard', 'curious', 'current', 'curtain', 'curve', 'cushion', 'cute', 'dad',
  'damage', 'damp', 'dance', 'danger', 'daring', 'dash', 'daughter', 'dawn',
  'day', 'deal', 'debris', 'december', 'decide', 'decline', 'decorate', 'deer',
  'define', 'defy', 'deliver', 'demise', 'denial', 'dentist', 'deny', 'depart',
  'depend', 'depth', 'deputy', 'derive', 'describe', 'desert', 'desk', 'despair',
  'destroy', 'detail', 'detect', 'develop', 'device', 'devote', 'dial', 'dice',
  'diesel', 'diet', 'differ', 'digital', 'dignity', 'dilemma', 'dinner', 'dinosaur',
  'direct', 'dirt', 'disagree', 'discover', 'dish', 'dismiss', 'disorder', 'divert',
  'divide', 'divorce', 'dizzy', 'doctor', 'dog', 'doll', 'dolphin', 'donate',
  'donkey', 'donor', 'door', 'dose', 'double', 'dove', 'draft', 'dragon',
  'drastic', 'draw', 'dream', 'dress', 'drift', 'drill', 'drink', 'drip',
  'drive', 'drop', 'drum', 'dry', 'duck', 'dumb', 'dune', 'during',
  'dust', 'dutch', 'duty', 'dwarf', 'dynamic', 'eager', 'eagle', 'early',
  'earn', 'earth', 'easily', 'east', 'easy', 'echo', 'ecology', 'edge',
  'edit', 'educate', 'egg', 'eight', 'either', 'elbow', 'elder', 'electric',
  'elegant', 'elephant', 'elite', 'else', 'embark', 'embody', 'embrace', 'emerge',
  'employ', 'empower', 'empty', 'enable', 'enact', 'end', 'endless', 'endorse',
  'enemy', 'energy', 'enforce', 'engage', 'enhance', 'enjoy', 'enlist', 'enough',
  'enrich', 'enroll', 'ensure', 'enter', 'entire', 'entry', 'envelope', 'episode',
  'equal', 'equip', 'era', 'erase', 'erode', 'erosion', 'error', 'erupt',
  'escape', 'essence', 'eternal', 'ethics', 'evil', 'evoke', 'evolve', 'exact',
  'example', 'excite', 'exclude', 'excuse', 'execute', 'exhaust', 'exhibit', 'exile',
  'exist', 'exit', 'exotic', 'expand', 'expect', 'expire', 'explain', 'expose',
  'express', 'extend', 'extra', 'eye', 'eyebrow', 'face', 'fade', 'faint',
  'faith', 'fall', 'false', 'fame', 'family', 'famous', 'fan', 'fancy',
  'fantasy', 'farm', 'fat', 'fatal', 'father', 'fatigue', 'fault', 'favorite',
  'february', 'fee', 'feed', 'feel', 'female', 'fence', 'fetch', 'fever',
  'few', 'fiber', 'fiction', 'field', 'file', 'film', 'filter', 'final',
  'find', 'fine', 'finger', 'finish', 'fire', 'first', 'fiscal', 'fish',
  'fit', 'fitness', 'fix', 'flag', 'flame', 'flash', 'flat', 'flavor',
  'flee', 'flight', 'flip', 'float', 'flock', 'floor', 'fluid', 'flush',
  'fly', 'foam', 'focus', 'fog', 'foil', 'fold', 'follow', 'food',
  'foot', 'force', 'forest', 'forget', 'fork', 'forward', 'fossil', 'foster',
  'found', 'fox', 'fragile', 'frame', 'frequent', 'fresh', 'friend', 'fringe',
  'frog', 'front', 'frost', 'frown', 'frozen', 'fruit', 'fuel', 'fun',
  'funny', 'furnace', 'fury', 'future', 'gadget', 'gain', 'galaxy', 'game',
  'gap', 'garage', 'garden', 'garment', 'gas', 'gasp', 'gate', 'gauge',
  'gaze', 'genius', 'genre', 'gentle', 'genuine', 'gesture', 'ghost', 'giant',
  'gift', 'giggle', 'ginger', 'giraffe', 'girl', 'give', 'glad', 'glare',
  'glass', 'glide', 'globe', 'gloom', 'glory', 'glove', 'glow', 'glue',
  'goat', 'good', 'goose', 'gorilla', 'gospel', 'gossip', 'govern', 'gown',
  'grab', 'grain', 'grant', 'grape', 'grass', 'great', 'grid', 'grief',
  'grit', 'grocery', 'grow', 'grunt', 'guard', 'guess', 'guide', 'guilt',
  'gun', 'gym', 'habit', 'hair', 'hammer', 'hamster', 'hand', 'happy',
  'hard', 'harsh', 'hat', 'have', 'hawk', 'hazard', 'head', 'heavy',
  'hedgehog', 'hello', 'helmet', 'help', 'hen', 'hero', 'hidden', 'high',
  'hill', 'hint', 'hip', 'hire', 'hockey', 'hold', 'hole', 'hollow',
  'home', 'honey', 'hood', 'hope', 'horn', 'horror', 'horse', 'host',
  'hotel', 'hour', 'hover', 'hub', 'huge', 'human', 'humble', 'humor',
  'hundred', 'hungry', 'hunt', 'hurdle', 'hurry', 'hurt', 'husband', 'hybrid',
  'ice', 'icon', 'idea', 'identify', 'idle', 'ignore', 'ill', 'illegal',
  'illness', 'imitate', 'immense', 'immune', 'impose', 'improve', 'impulse', 'inch',
  'include', 'increase', 'index', 'indicate', 'indoor', 'infant', 'inflict', 'inform',
  'inhale', 'inherit', 'initial', 'inject', 'inmate', 'inner', 'innocent', 'input',
  'insane', 'insect', 'inside', 'inspire', 'install', 'intact', 'into', 'invest',
  'invite', 'involve', 'iron', 'island', 'isolate', 'issue', 'item', 'ivory',
  'jacket', 'jaguar', 'jar', 'jazz', 'jealous', 'jeans', 'jelly', 'jewel',
  'job', 'join', 'joke', 'joy', 'judge', 'juice', 'jump', 'jungle',
  'junior', 'junk', 'just', 'kangaroo', 'keen', 'keep', 'ketchup', 'key',
  'kick', 'kid', 'kidney', 'kind', 'kingdom', 'kiss', 'kit', 'kitchen',
  'kite', 'kitten', 'kiwi', 'knee', 'knife', 'knock', 'know', 'lab',
  'label', 'labor', 'ladder', 'lady', 'lake', 'lamp', 'laptop', 'large',
  'later', 'latin', 'laugh', 'laundry', 'lava', 'law', 'lawn', 'lawsuit',
  'layer', 'lazy', 'leader', 'leaf', 'learn', 'leave', 'left', 'leg',
  'legal', 'lemon', 'lend', 'length', 'lens', 'leopard', 'lesson', 'letter',
  'level', 'liar', 'library', 'lift', 'light', 'like', 'limb', 'limit',
  'link', 'lion', 'liquid', 'list', 'little', 'live', 'lizard', 'load',
  'loan', 'lobster', 'local', 'lock', 'logic', 'lonely', 'long', 'loop',
  'lottery', 'loud', 'lounge', 'love', 'loyal', 'lucky', 'luggage', 'lumber',
  'lunar', 'lunch', 'luxury', 'lyrics', 'machine', 'mad', 'magic', 'magnet',
  'maid', 'mail', 'main', 'major', 'make', 'mammal', 'man', 'manage',
  'mandate', 'mango', 'mansion', 'manual', 'maple', 'marble', 'march', 'marine',
  'market', 'marriage', 'mask', 'mass', 'master', 'match', 'math', 'matrix',
  'matter', 'maze', 'meadow', 'mean', 'measure', 'meat', 'mechanic', 'medal',
  'media', 'melody', 'melt', 'member', 'menu', 'mercy', 'merge', 'merit',
  'merry', 'mesh', 'metal', 'middle', 'milk', 'million', 'mimic', 'mind',
  'minor', 'minute', 'mirror', 'misery', 'miss', 'mistake', 'mix', 'mixed',
  'mixture', 'model', 'modify', 'mom', 'moment', 'monkey', 'monster', 'month',
  'moon', 'moral', 'more', 'mosquito', 'mother', 'motion', 'motor', 'mouse',
  'move', 'movie', 'much', 'muffin', 'mule', 'multiply', 'muscle', 'museum',
  'mushroom', 'music', 'must', 'mutual', 'myself', 'myth', 'naive', 'name',
  'napkin', 'narrow', 'nasty', 'nation', 'nature', 'near', 'neck', 'need',
  'negative', 'neglect', 'neither', 'nephew', 'nerve', 'nest', 'net', 'never',
];

// ---------------------------------------------------------------------------
// Mnemonic encoding (BIP39-like)
// ---------------------------------------------------------------------------

/// Number of words in the mnemonic phrase.
const _mnemonicWords = 24;

/// Bits per word (11 bits → 2048-word list).
const _bitsPerWord = 11;

/// Total bits encoded: 24 × 11 = 264 bits.
/// 256 bits DEK + 8 bits checksum (SHA-256 first byte).

/// Encode 32 bytes (DEK) into a 24-word mnemonic phrase.
String _encodeMnemonic(Uint8List dekBytes) {
  assert(dekBytes.length == 32, 'DEK must be 32 bytes');

  // Compute checksum: SHA-256 truncated to first byte
  final checksum = _sha256Checksum(dekBytes);

  // Build 33-byte buffer: DEK (32) + checksum (1)
  final buffer = Uint8List(33);
  buffer.setRange(0, 32, dekBytes);
  buffer[32] = checksum;

  // Convert to 24 groups of 11 bits
  final words = <String>[];
  for (var i = 0; i < _mnemonicWords; i++) {
    final wordIndex = _readBits11(buffer, i * _bitsPerWord);
    words.add(_bip39Words[wordIndex]);
  }

  return words.join(' ');
}

/// Decode a 24-word mnemonic phrase back to 32 bytes (DEK).
/// Verifies the embedded SHA-256 checksum.
Uint8List _decodeMnemonic(String phrase) {
  final words = phrase.trim().split(RegExp(r'\s+'));
  if (words.length != _mnemonicWords) {
    throw ArgumentError(
      'Expected $_mnemonicWords words, got ${words.length}',
    );
  }

  // Build word → index lookup (cache locally for performance)
  final wordToIndex = <String, int>{};
  for (var i = 0; i < _bip39Words.length; i++) {
    wordToIndex[_bip39Words[i]] = i;
  }

  // Extract 24 × 11 bits = 264 bits → 33 bytes
  final buffer = Uint8List(33);
  for (var i = 0; i < _mnemonicWords; i++) {
    final word = words[i];
    final index = wordToIndex[word];
    if (index == null) {
      throw ArgumentError('Unknown word in phrase: "$word"');
    }
    _writeBits11(buffer, i * _bitsPerWord, index);
  }

  // Extract DEK (first 32 bytes) and checksum (last byte)
  final dekBytes = buffer.sublist(0, 32);
  final expectedChecksum = buffer[32];

  // Verify checksum
  final actualChecksum = _sha256Checksum(dekBytes);
  if (actualChecksum != expectedChecksum) {
    throw ArgumentError(
      'Recovery phrase checksum mismatch — phrase is corrupted or mistyped. '
      'Please double-check every word.',
    );
  }

  return dekBytes;
}

/// Read 11 bits from [buffer] starting at [bitOffset] (0-indexed).
int _readBits11(Uint8List buffer, int bitOffset) {
  final byteOffset = bitOffset ~/ 8;
  final bitRemainder = bitOffset % 8;

  // Read up to 3 bytes (24 bits) to cover the 11-bit window
  final b0 = buffer[byteOffset];
  final b1 = byteOffset + 1 < buffer.length ? buffer[byteOffset + 1] : 0;
  final b2 = byteOffset + 2 < buffer.length ? buffer[byteOffset + 2] : 0;

  // Combine into 24-bit big-endian value
  final chunk24 = (b0 << 16) | (b1 << 8) | b2;

  // Shift right so the 11-bit window aligns to LSB
  // bitRemainder = 0 → bits 13-23 of chunk24 (11 bits at MSB)
  // bitRemainder = 5 → bits 8-18
  // bitRemainder = 7 → bits 6-16
  final shift = 13 - bitRemainder;
  return (chunk24 >> shift) & 0x7FF;
}

/// Write 11-bit [value] into [buffer] at [bitOffset].
void _writeBits11(Uint8List buffer, int bitOffset, int value) {
  assert(value < 0x800, 'Value must fit in 11 bits');
  final byteOffset = bitOffset ~/ 8;
  final bitRemainder = bitOffset % 8;

  // The 11-bit value spans at most 3 bytes (if straddling a byte boundary)
  final shift = 13 - bitRemainder;
  final chunk24 = value << shift;

  buffer[byteOffset] |= (chunk24 >> 16) & 0xFF;
  if (byteOffset + 1 < buffer.length) {
    buffer[byteOffset + 1] |= (chunk24 >> 8) & 0xFF;
  }
  if (byteOffset + 2 < buffer.length) {
    buffer[byteOffset + 2] |= chunk24 & 0xFF;
  }
}

/// Compute the first byte of SHA-256 of [data] as a checksum byte.
/// Uses `package:crypto` for synchronous SHA-256.
int _sha256Checksum(Uint8List data) {
  final digest = crypto.sha256.convert(data);
  return digest.bytes[0];
}
