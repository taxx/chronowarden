import 'package:flutter/material.dart';

import '../app_info.dart';
import '../widgets/external_link.dart';

/// Detailed explanation of the app's encryption model.
///
/// Accessible from Settings → "How encryption works".
class AboutEncryptionScreen extends StatelessWidget {
  const AboutEncryptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encryption & Privacy'),
      ),
      body: SafeArea(
        child: const EncryptionInfoContent(),
      ),
    );
  }
}

/// Shared explainer content — used both by the full screen (Settings) and
/// the login screen's modal dialog, so the two stay in sync.
class EncryptionInfoContent extends StatelessWidget {
  const EncryptionInfoContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // --- Overview ---
                Text(
                  'How ChronoWarden Protects Your Data',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  theme,
                  'Zero-Knowledge Architecture',
                  'ChronoWarden uses a zero-knowledge encryption model. '
                  'Your data is encrypted on your device before it ever '
                  'reaches the server. The server stores only ciphertext — '
                  'it cannot read your actual data. Even the app administrator '
                  'cannot decrypt your information.',
                ),
                const SizedBox(height: 24),

                // --- Key hierarchy diagram ---
                Text(
                  'Key Hierarchy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _keyHierarchyDiagram(theme),
                const SizedBox(height: 24),

                // --- Layer explanations ---
                _layerCard(
                  theme,
                  'Layer 1: Your Encryption Passphrase',
                  Icons.lock,
                  Colors.blue,
                  'You choose a passphrase (at least 8 characters). '
                  'This passphrase is never stored — it exists only in '
                  'your memory. During login, it is used momentarily to '
                  'derive a Master Key, then discarded.',
                ),
                const SizedBox(height: 12),
                _layerCard(
                  theme,
                  'Layer 2: Master Key (Key Encryption Key)',
                  Icons.key,
                  Colors.indigo,
                  'Derived from your passphrase using PBKDF2-HMAC-SHA256 '
                  'with 310,000 iterations (OWASP 2025 standard). '
                  'This key exists only in device memory during your session. '
                  'It is used to unlock your Data Encryption Key.',
                ),
                const SizedBox(height: 12),
                _layerCard(
                  theme,
                  'Layer 3: Data Encryption Key (DEK)',
                  Icons.verified_outlined,
                  Colors.teal,
                  'A random 256-bit AES key generated when you first set '
                  'up encryption. The DEK is encrypted ("wrapped") by your '
                  'Master Key and stored on the server. It never appears '
                  'in plaintext on the server. On login, your device unwraps '
                  'it using your Master Key.',
                ),
                const SizedBox(height: 12),
                _layerCard(
                  theme,
                  'Layer 4: Encrypted Data',
                  Icons.data_object,
                  Colors.green,
                  'All your time logs, travel presets, and settings are '
                  'encrypted with AES-256-GCM using the DEK. Each encrypted '
                  'blob includes a unique nonce and authentication tag to '
                  'prevent tampering.',
                ),
                const SizedBox(height: 24),

                // --- Multi-device ---
                Text(
                  'Using Multiple Devices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  theme,
                  'Cross-Device Access',
                  'Your DEK is stored encrypted on the server. Any device '
                  'can unwrap it if you provide your encryption passphrase. '
                  'This means you can use the app on multiple devices '
                  'without needing to transfer keys manually.',
                ),
                const SizedBox(height: 12),
                _section(
                  theme,
                  'Session Persistence',
                  'For convenience, the unwrapped DEK is cached in browser '
                  'localStorage. This means refreshing the page (F5) and '
                  'reopening the browser tab do not require re-entering your '
                  'passphrase. The cache is cleared when you sign out.',
                ),
                const SizedBox(height: 24),

                // --- Recovery ---
                Text(
                  'Recovery Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  theme,
                  'Recovery Phrase',
                  'When you first set up encryption, a 24-word recovery '
                  'phrase is generated. This phrase encodes your DEK '
                  'directly (not wrapped by your Master Key). If you '
                  'forget your passphrase, you can enter this recovery '
                  'phrase to regain access to your data.',
                ),
                const SizedBox(height: 12),
                _dangerBox(theme),
                const SizedBox(height: 24),

                // --- Technical details ---
                Text(
                  'Technical Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _techDetail(theme, 'Encryption algorithm',
                    'AES-256-GCM (authenticated encryption)'),
                _techDetail(theme, 'Key derivation',
                    'PBKDF2-HMAC-SHA256, 310,000 iterations'),
                _techDetail(theme, 'Key wrapping',
                    'AES-256-GCM (same algorithm, different key)'),
                _techDetail(theme, 'Recovery encoding',
                    'BIP39-style 24-word mnemonic phrase'),
                _techDetail(theme, 'Session cache',
                    'Browser localStorage (cleared on sign out)'),
                _techDetail(theme, 'Server storage',
                    'Ciphertext only — server cannot read plaintext'),
                const SizedBox(height: 24),

                // --- Open source ---
                Text(
                  'Open Source',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  theme,
                  'Free & Auditable',
                  '${AppInfo.name} is released under the '
                  '${AppInfo.licenseName}. Anyone can read the code, verify '
                  'that the encryption above works as described, self-host '
                  'it, or contribute improvements.',
                ),
                const SizedBox(height: 12),
                ExternalLinkButton(
                  label: 'View source on GitHub',
                  url: AppInfo.repoUrl,
                  icon: Icons.code,
                ),
                const SizedBox(height: 8),
                ExternalLinkButton(
                  label: 'Report an issue',
                  url: AppInfo.issuesUrl,
                  icon: Icons.bug_report_outlined,
                ),
              ],
            ),
          ),
      );
  }

  Widget _section(ThemeData theme, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _keyHierarchyDiagram(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _diagramRow('🔐', 'Your Passphrase', 'Never stored'),
          _arrowDown(),
          _diagramRow('🔑', 'Master Key (KEK)', 'In memory only'),
          _arrowDown(),
          _diagramRow('🗝️', 'Data Encryption Key (DEK)', 'Wrapped on server'),
          _arrowDown(),
          _diagramRow('📦', 'Encrypted Data', 'AES-256-GCM ciphertext'),
        ],
      ),
    );
  }

  Widget _diagramRow(String icon, String label, String note) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(note,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrowDown() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Icon(Icons.arrow_downward, size: 18, color: Colors.grey),
    );
  }

  Widget _layerCard(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    String body,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerBox(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning,
              color: theme.colorScheme.onErrorContainer, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Critical Warning',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If you lose both your encryption passphrase AND your '
                  '24-word recovery phrase, your data is gone forever. '
                  'No one — not even the app administrator — can recover it. '
                  'There is no backdoor, no password reset, no support '
                  'ticket that can restore your data.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _techDetail(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            )),
          ),
        ],
      ),
    );
  }
}
