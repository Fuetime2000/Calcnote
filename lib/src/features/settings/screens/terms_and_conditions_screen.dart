import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Displays CalcNote terms and conditions content using Markdown.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String _termsMarkdown = '''# CalcNote Terms & Conditions

_Last updated: November 2025_

## 1. Acceptance of Terms
By installing or using CalcNote, you agree to these Terms & Conditions. If you do not agree, uninstall the application and discontinue use.

## 2. Eligibility
You must be at least 13 years old or have parental/guardian permission to use CalcNote. You are responsible for ensuring that your use complies with local laws and regulations.

## 3. Local, Offline Use
CalcNote is designed for offline, on-device use. You are responsible for safeguarding your device, managing backups, and controlling any sharing of data you initiate.

## 4. License
CalcNote grants you a limited, non-transferable license to install and use the app for personal purposes. You may not reverse engineer, redistribute, or resell the application without explicit permission.

## 5. User Content
All notes, PDFs, and other content you create remain yours. You confirm you have the right to store any content you add and that it does not violate applicable laws or third-party rights.

## 6. Data Handling
- CalcNote stores data locally using Hive databases and device storage.
- Optional security features (PIN, biometric, PDF passwords) rely on device secure storage.
- Backups you create remain under your control; exporting or sharing them is your responsibility.

## 7. Permissions & Third-Party Packages
CalcNote may request permissions (storage, Bluetooth, biometrics, microphone) solely to deliver app features. Integrated Flutter packages execute locally and do not transmit data to external servers.

## 8. Prohibited Use
You agree not to:
- Use CalcNote for unlawful activities or to store illegal content.
- Attempt to disrupt or reverse engineer the application.
- Infringe on intellectual property or privacy rights of others.

## 9. Disclaimer of Warranty
CalcNote is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free operation or that the app will meet your requirements.

## 10. Limitation of Liability
To the maximum extent permitted by law, CalcNote and its contributors are not liable for damages arising from your use of the app, including data loss or device issues.

## 11. Updates & Changes
These terms may be updated as CalcNote evolves. Continued use after updates constitutes acceptance of the revised terms.

## 12. Contact
For questions regarding these terms, email **help@calcnote.com**

---
By continuing to use CalcNote you acknowledge that you have read, understood, and agree to these Terms & Conditions.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: const Markdown(
        data: _termsMarkdown,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        selectable: true,
      ),
    );
  }
}
