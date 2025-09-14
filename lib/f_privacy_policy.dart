import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  final Color ilocateRed = const Color(0xFFC70000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ilocateRed,
        toolbarHeight: 90.0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'PRIVACY POLICY',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  children: [
                    const SizedBox(height: 10.0),
                    const Text(
                      'Privacy Policy for ILocate',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    const Text(
                      'We respect your privacy and is committed to safeguarding your personal information. This Privacy Policy outlines how we collect, use, store, and protect your data when you use our educational disaster responder app. By using the App, you agree to the terms of this Privacy Policy.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16.0),
                    buildSection(
                      number: '1. Information We Collect',
                      content:
                          'In the course of providing educational content, we may collect minimal personal information, but only as necessary for providing the app’s educational features.\n\n'
                          '• Personal Identification Information: Only basic information like name or email address may be collected if required for account creation or notifications. This information will never be used for commercial purposes.\n'
                          '• Device Information: Information such as device type, operating system, and device settings may be collected for troubleshooting and improving the app’s educational experience.\n'
                          '• Usage Data: We may collect data on how you interact with the app (e.g., learning modules accessed, time spent on lessons) to improve content and user experience. This data is aggregated and anonymized to ensure privacy.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '2. How We Use Your Information',
                      content:
                          'The data we collect will be used solely for the purpose of providing educational content and improving the user experience within the App:\n'
                          '• To deliver educational content related to disaster response.\n'
                          '• To analyze app usage and improve the effectiveness of educational materials.\n'
                          '• To communicate with you about updates or new educational resources.\n'
                          '• To ensure the app functions as intended and provide support.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '3. Sharing Your Information',
                      content:
                          'We do not sell, rent, or share your personal information with third parties for commercial purposes. However, in certain limited circumstances, we may share data:\n'
                          '• Service Providers: We may use third-party services to help manage the app (e.g., cloud storage or customer support). These providers may have access to some of your information, but they are strictly prohibited from using it for any other purposes.\n'
                          '• Legal Requirements: In rare cases, we may disclose information if required to comply with legal obligations, such as responding to a subpoena or other legal processes.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '4. Security',
                      content:
                          'We take reasonable steps to protect your information from unauthorized access, use, or disclosure. However, please be aware that no method of data transmission or storage is completely secure, and we cannot guarantee absolute security.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '5. Your Rights',
                      content:
                          'As this app is for educational purposes, we respect your rights to control your information:\n'
                          '• Access and Correction: You may request access to your personal information or ask us to correct inaccuracies.\n'
                          '• Deletion: You may request that we delete your personal information, except where required for legal or educational record-keeping purposes.\n'
                          '• Opt-Out: If we send you notifications or updates, you can opt out by following the unsubscribe instructions.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '6. Contact Us',
                      content:
                          'If you have any questions or concerns about this Privacy Policy or how we handle your personal information, please contact us at: +639284832828',
                      isLargeTitle: true,
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      '~ PRIVACY POLICY ~',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ilocateRed,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      // Navigate back to the Settings page with the navigation bar
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'I UNDERSTAND',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSection({
    required String number,
    required String content,
    bool isLargeTitle = false,
  }) {
    List<Widget> buildBulletPoints(String text) {
      final lines = text.split('\n');
      final children = <Widget>[];

      for (final line in lines) {
        if (line.trim().startsWith('•')) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16.0, color: Colors.black)),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: parseMarkdown(line.substring(1).trim())),
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black,
                        height: 1.5,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          children.add(
            Text.rich(
              TextSpan(children: parseMarkdown(line)),
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
                height: 1.5,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.justify,
            ),
          );
        }
      }
      return children;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: isLargeTitle ? 20.0 : 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4.0),
          ...buildBulletPoints(content),
        ],
      ),
    );
  }

  List<InlineSpan> parseMarkdown(String text) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final spans = <InlineSpan>[];
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}