import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: AppBar(
        backgroundColor: XColors.primaryBG,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: XColors.primaryText, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: XColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: XColors.borderColor.withOpacity(0.4),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _TermsHeader(),
          const SizedBox(height: 28),
          _TermsSection(
            number: '1',
            title: 'Acceptance of Terms',
            content:
                'By creating an account and using FitBud, you confirm that you have read, understood, and agree to be bound by these Terms & Conditions. '
                'If you do not agree to any part of these terms, you must not use the FitBud application.\n\n'
                'We reserve the right to update these terms at any time. Continued use of the app following any updates constitutes your acceptance of the revised terms.',
          ),
          _TermsSection(
            number: '2',
            title: 'Eligibility',
            content:
                'You must be at least 16 years of age to use FitBud. By using the app, you represent and warrant that:\n\n'
                '• You are 16 years of age or older.\n\n'
                '• You have the legal capacity to enter into a binding agreement.\n\n'
                '• Your use of the app does not violate any applicable law or regulation in your jurisdiction.',
          ),
          _TermsSection(
            number: '3',
            title: 'User Accounts',
            content:
                'To access most features of FitBud, you must register an account. You agree to:\n\n'
                '• Provide accurate, current, and complete information during registration.\n\n'
                '• Keep your account credentials confidential and not share your password with others.\n\n'
                '• Notify us immediately of any unauthorized use of your account.\n\n'
                '• Take full responsibility for all activities that occur under your account.\n\n'
                'We reserve the right to terminate accounts that violate these terms or engage in harmful behavior.',
          ),
          _TermsSection(
            number: '4',
            title: 'Acceptable Use',
            content:
                'You agree to use FitBud only for lawful purposes and in a manner that does not infringe the rights of others. You must not:\n\n'
                '• Post or share content that is offensive, abusive, harassing, or discriminatory.\n\n'
                '• Impersonate any person or entity, or misrepresent your affiliation.\n\n'
                '• Use the app to distribute spam, unsolicited messages, or malware.\n\n'
                '• Attempt to gain unauthorized access to other users\' accounts or our systems.\n\n'
                '• Use automated tools to scrape, mine, or harvest data from the app.\n\n'
                '• Engage in any activity that could damage, disable, or impair the FitBud service.',
          ),
          _TermsSection(
            number: '5',
            title: 'Fitness & Health Disclaimer',
            content:
                'FitBud is a social fitness platform and does not provide medical advice, diagnosis, or treatment. '
                'The content and features available in the app are for informational and social purposes only.\n\n'
                'Before beginning any fitness program, you should consult a qualified healthcare professional. '
                'FitBud is not responsible for any injury, illness, or health consequence arising from activities '
                'organized, suggested, or connected through the app.',
          ),
          _TermsSection(
            number: '6',
            title: 'Buddy Matching & Social Features',
            content:
                'FitBud provides tools to connect you with other fitness enthusiasts. We do not screen, verify, or '
                'endorse any user or their fitness credentials. You agree that:\n\n'
                '• You interact with other users at your own risk.\n\n'
                '• We are not responsible for the conduct of other users, whether online or offline.\n\n'
                '• You will report any abusive, threatening, or inappropriate behavior through the app.\n\n'
                '• Meeting other users in person carries inherent risks that FitBud cannot control or be liable for.',
          ),
          _TermsSection(
            number: '7',
            title: 'Subscriptions & Payments',
            content:
                'FitBud offers premium subscription plans with additional features. By subscribing:\n\n'
                '• You authorize us to charge the applicable fees to your chosen payment method.\n\n'
                '• Subscriptions automatically renew unless cancelled before the renewal date.\n\n'
                '• Refunds are handled in accordance with the app store policies (Apple App Store / Google Play).\n\n'
                '• We reserve the right to modify pricing with reasonable prior notice to subscribers.',
          ),
          _TermsSection(
            number: '8',
            title: 'Intellectual Property',
            content:
                'All content, features, and functionality within FitBud — including but not limited to text, graphics, '
                'logos, icons, and software — are the exclusive property of FitBud and are protected by applicable '
                'intellectual property laws.\n\n'
                'You are granted a limited, non-exclusive, non-transferable license to use the app for personal, '
                'non-commercial purposes. You may not reproduce, distribute, or create derivative works without our express written consent.',
          ),
          _TermsSection(
            number: '9',
            title: 'Limitation of Liability',
            content:
                'To the fullest extent permitted by law, FitBud and its affiliates shall not be liable for any indirect, '
                'incidental, special, consequential, or punitive damages arising from your use of the app, '
                'including but not limited to loss of data, personal injury, or property damage.\n\n'
                'Our total liability for any claim arising out of or relating to these terms shall not exceed '
                'the amount you paid to FitBud in the 12 months preceding the claim.',
          ),
          _TermsSection(
            number: '10',
            title: 'Termination',
            content:
                'We may suspend or terminate your account at any time, with or without notice, if we determine that '
                'you have violated these Terms & Conditions or engaged in conduct harmful to other users or the service.\n\n'
                'Upon termination, your right to use FitBud will immediately cease. Provisions that by their nature '
                'should survive termination — including intellectual property rights and liability disclaimers — shall survive.',
          ),
          _TermsSection(
            number: '11',
            title: 'Governing Law',
            content:
                'These Terms & Conditions are governed by and construed in accordance with applicable laws. '
                'Any disputes arising from these terms shall be resolved through good-faith negotiation, '
                'and if unresolved, through binding arbitration or the courts of competent jurisdiction.',
          ),
          _TermsSection(
            number: '12',
            title: 'Contact Us',
            content:
                'If you have any questions about these Terms & Conditions, please contact us:\n\n'
                '• Email: legal@fitbud.app\n\n'
                '• Support: Available through the Help & Support section in Settings\n\n'
                'We aim to respond to all inquiries within 3 business days.',
          ),
          const SizedBox(height: 12),
          _LastUpdatedFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            XColors.primary.withOpacity(0.12),
            XColors.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: XColors.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: XColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: XColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Please Read Carefully',
                  style: TextStyle(
                    color: XColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'These Terms & Conditions govern your access to and use of FitBud. '
            'By creating an account, you agree to comply with and be bound by the terms below.',
            style: TextStyle(
              color: XColors.bodyText.withOpacity(0.8),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: XColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: XColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: XColors.primaryText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: XColors.secondaryBG.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: XColors.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: XColors.bodyText.withOpacity(0.75),
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: XColors.secondaryBG.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: XColors.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 15,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: February 2026',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
