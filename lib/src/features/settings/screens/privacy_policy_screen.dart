import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Displays the CalcNote privacy policy content using Markdown rendering.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _policyMarkdown = '''# CalcNote Privacy Policy

_Last updated: November 2025_

## 1. Overview
CalcNote is an offline-first notes, calculator, and PDF management application. All core features—including note storage, PDF editing, AI assistance, and backups—run locally on your device. No account registration or cloud synchronization is required or supported.

## 2. Information We Collect
We only process information that you choose to store or import into the app:

1. **Notes and Tags** – Titles, bodies, tags, summaries, categories, and calculator results are saved in local Hive databases on your device.
2. **PDF Attachments & Metadata** – Imported PDFs, extracted text, annotations, thumbnails, and usage timestamps are stored in local app directories and Hive boxes; optional passwords are stored using Flutter Secure Storage.
3. **Security Credentials** – PIN codes and biometric preferences you configure for App Lock are retained securely via Flutter Secure Storage.
4. **Backups** – When you manually or automatically create backups, CalcNote writes JSON exports to the device file system; exporting uses your chosen sharing channel (e.g., email, messaging apps).
5. **Bluetooth Sharing Data** – Notes you decide to transmit via Bluetooth are serialized and sent directly to the target device during that session.
6. **AI Assistance Inputs** – AI formula detection, summarization, translation, and suggestions operate entirely offline on the text you type or import. No external servers receive that data.
7. **Optional Voice Features** – Voice input is currently disabled; if re-enabled, it will process speech locally after you grant microphone permission.

CalcNote does **not** collect analytics, advertising identifiers, or crash reports, and it does not transmit your content to remote servers.

## 3. How We Use Information
All processing happens locally to deliver app functionality:

- Saving, editing, searching, and organizing notes and PDFs.
- Generating quick calculations, summaries, tags, and smart suggestions using on-device AI services.
- Encrypting PDF passwords (when enabled) and enforcing biometric/PIN locks for app access.
- Creating local backups you can export or delete at any time.

## 4. Data Storage & Retention
- Notes and PDFs remain on your device until you delete them or uninstall the app.
- Secure credentials (PINs, PDF passwords) stay in encrypted device storage until you remove them or reset security settings.
- Backups persist in the local "backups" directory until you delete them.

## 5. Device Permissions
CalcNote requests permissions only when needed for specific features:

1. **Storage / File Access** – Required to import/export PDFs, create backups, and save local files.
2. **Bluetooth** – Needed for optional device-to-device note sharing.
3. **Microphone** – Only requested if you enable voice input when it becomes available.
4. **Biometrics** – Used for fingerprint/face authentication when you enable App Lock.

You may revoke permissions at any time through your device settings; doing so may disable the related feature.

## 6. Third-Party Frameworks
CalcNote integrates trusted, locally executed Flutter packages (e.g., Hive for storage, Syncfusion for PDF parsing, Share Plus for exporting, Flutter Blue Plus for Bluetooth). These libraries execute within the app sandbox and do not transmit your personal data outside the device.

## 7. Data Sharing & Transfers
CalcNote does not share your data with any external servers. Sharing occurs only when you explicitly export backups, PDFs, or notes via third-party apps or Bluetooth.

## 8. Security Measures
- Sensitive credentials (PINs, PDF passwords) rely on platform-secure storage APIs.
- Optional PDF compression and encryption features help you manage attachments securely.
- Biometric/PIN locks guard access to the app when enabled.

You are responsible for safeguarding your device, backups, and exported files.

## 9. Your Choices
- Delete notes, PDFs, or backups from within the app interfaces.
- Clear secure credentials by resetting App Lock or uninstalling the app.
- Disable permissions via device settings (which may limit features).

## 10. Children’s Privacy
CalcNote is not directed to children under 13. If you believe a minor has stored content that should be removed, delete it from the device or uninstall the app.

## 11. Changes to This Policy
We may update this policy as CalcNote evolves (e.g., if online sync or cloud AI features are introduced). Significant changes will be reflected in app release notes and the policy date.

## 12. Contact
For privacy questions or feedback, please contact us at: **help@calcnote.com**

---
By using CalcNote, you acknowledge this privacy policy and understand that all data remains on your device unless you actively export or share it.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const Markdown(
        data: _policyMarkdown,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        selectable: true,
      ),
    );
  }
}
