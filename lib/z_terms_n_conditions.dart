import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  final Color ilocateRed = const Color(0xFFC70000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ilocateRed,
        toolbarHeight: 90.0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          // This will go back to the previous screen on the navigation stack,
          // which should be z_Settings.dart, as per the user's request.
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
          'TERMS & CONDITIONS OF USE',
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
                      'ILocate – Disaster Responder App',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    const Text(
                      'Developed by:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Edward John Alawag', style: TextStyle(fontSize: 16.0, color: Colors.black)),
                          Text('• Nar Anthony Esguerra', style: TextStyle(fontSize: 16.0, color: Colors.black)),
                          Text('• James Marlo Peñaflor', style: TextStyle(fontSize: 16.0, color: Colors.black)),
                          Text('• Jan Matthew Tanchanco', style: TextStyle(fontSize: 16.0, color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Institution: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'Batangas State University JPLPC-Malvar Campus',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(thickness: 1.0),
                    const SizedBox(height: 12.0),

                    buildSection(
                      number: '1. Acceptance of Terms',
                      content:
                          'By using the **ILocate** mobile application, you agree to comply with and be bound by these Terms and Conditions of Use. If you do not agree to these terms, please do not use the App.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '2. Educational Purpose Only',
                      content:
                          '**ILocate** is a prototype application developed for academic purposes as part of a capstone project at **Batangas State University JPLPC-Malvar Campus**. The App is not a certified emergency response tool and must not be used in real-life disaster situations or relied upon for safety-critical operations.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '3. Personal Data Collection',
                      content:
                          'Although this application is used for educational purposes, it may request or store personal information, including but not limited to:\n\n• Full Name\n• Email Address\n• Real-Time GPS Location\n• Role (e.g., Responder, Admin)\n• Device or Beacon ID\n\nThis data is used exclusively to simulate real-world disaster response systems and is not shared with any third-party organization outside the scope of academic evaluation.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '4. Data Usage & Storage',
                      content:
                          'Collected information will be:\n'
                          '• Used only within the project context\n'
                          '• Stored on secure local or cloud environments for testing and presentation\n'
                          '• Retained only as long as necessary to complete the project\n'
                          '• Accessible only by authorized student developers and faculty reviewers\n\n'
                          'You may request removal of your data at any time by contacting the development team.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '5. Prohibited Uses',
                      content:
                          'You agree not to:\n'
                          '• Use the App for real emergencies or safety-critical scenarios\n'
                          '• Submit false, misleading, or harmful data\n'
                          '• Interfere with the functionality of the App\n'
                          '• Attempt unauthorized access to backend systems or databases',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '6. No Liability',
                      content:
                          'This App is provided "as is" for demonstration purposes. The developers and Batangas State University JPLPC-Malvar Campus make no warranties regarding its reliability, accuracy, or fitness for any particular use. We are not liable for any loss or damage, direct or indirect, arising from the use of this App.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '7. Intellectual Property',
                      content:
                          'All intellectual property related to this project, including source code, design, and documentation, is owned by the developers and used solely for educational submission and portfolio purposes.',
                      isLargeTitle: true,
                    ),
                    buildSection(
                      number: '8. Modifications to Terms',
                      content:
                          'We reserve the right to update or modify these Terms and Conditions at any time. Changes will be reflected in the app or associated documentation.',
                      isLargeTitle: true,
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      '~ TERMS & CONDITIONS OF USE ~',
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
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'I AGREE',
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