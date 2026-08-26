/// Represents an encrypted data row in any of the data tables.
///
/// Each table (time_logs, travel_presets) stores:
///   - user_id (for RLS)
///   - date (for server-side filtering — time_logs only)
///   - encrypted_data (base64-encoded AES-GCM ciphertext)
///   - created_at (for sorting)
///
/// The plaintext JSON is the model's toJson() output.
class EncryptedEnvelope {
  final String? id;
  final String userId;
  final String? date;       // kept as plaintext index for filtering
  final String encryptedData; // base64: nonce(12) + ciphertext + mac(16)
  final String? createdAt;

  const EncryptedEnvelope({
    this.id,
    required this.userId,
    this.date,
    required this.encryptedData,
    this.createdAt,
  });

  factory EncryptedEnvelope.fromJson(Map<String, dynamic> json) {
    return EncryptedEnvelope(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      date: json['date'] as String?,
      encryptedData: json['encrypted_data'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (date != null) 'date': date,
      'encrypted_data': encryptedData,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
