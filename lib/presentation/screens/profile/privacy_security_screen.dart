import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

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
          'Privacy & Security',
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
          _PrivacyHeader(),
          const SizedBox(height: 28),
          _PrivacySection(
            number: '1',
            title: 'Information We Collect',
            content:
                'When you use FitBud, we collect information you provide directly to us, including:\n\n'
                '• Account information: name, email address, profile photo, and fitness preferences you provide during sign-up or profile setup.\n\n'
                '• Fitness data: workout sessions, gym check-ins, exercise preferences, fitness goals, and activity history.\n\n'
                '• Social data: buddy connections, chat messages, session invites, and buddy requests.\n\n'
                '• Device information: device type, operating system, app version, and push notification tokens used to deliver alerts to your device.\n\n'
                '• Usage data: features you interact with, screens you visit, and how you navigate the app.',
          ),
          _PrivacySection(
            number: '2',
            title: 'How We Use Your Information',
            content:
                'We use the information we collect to:\n\n'
                '• Provide, maintain, and improve the FitBud service, including personalizing your fitness buddy matches.\n\n'
                '• Enable communication between you and your fitness buddies through our in-app chat.\n\n'
                '• Send push notifications about buddy requests, session invites, and new messages — only with your permission.\n\n'
                '• Process subscription payments and manage your premium plan status.\n\n'
                '• Detect and prevent fraud, abuse, and security incidents.\n\n'
                '• Comply with legal obligations and enforce our Terms of Service.',
          ),
          _PrivacySection(
            number: '3',
            title: 'Data Sharing & Disclosure',
            content:
                'We do not sell your personal information to third parties. We may share your information in the following limited circumstances:\n\n'
                '• With other users: your public profile (name, photo, fitness preferences) is visible to other FitBud users when you appear in buddy searches or matches.\n\n'
                '• With service providers: we use Firebase (Google) for authentication, database storage, and push notifications. These services process data on our behalf under strict confidentiality agreements.\n\n'
                '• For legal reasons: we may disclose information if required by law, court order, or to protect the rights and safety of FitBud and its users.\n\n'
                '• In business transfers: if FitBud is acquired or merges with another company, your information may be transferred as part of that transaction.',
          ),
          _PrivacySection(
            number: '4',
            title: 'Data Retention',
            content:
                'We retain your personal information for as long as your account is active or as needed to provide you with our services. '
                'You can request deletion of your account and associated data at any time through the Settings screen.\n\n'
                'After deletion, we may retain certain information in anonymized or aggregated form for analytics and service improvement, '
                'or where required by law.',
          ),
          _PrivacySection(
            number: '5',
            title: 'Security',
            content:
                'We take the security of your personal information seriously and implement industry-standard measures to protect it:\n\n'
                '• All data is transmitted over encrypted HTTPS/TLS connections.\n\n'
                '• Authentication is handled by Firebase Authentication, which uses secure, industry-standard protocols.\n\n'
                '• Access to your data is restricted to authorized personnel only, on a need-to-know basis.\n\n'
                '• We regularly review and update our security practices.\n\n'
                'No system is completely secure. If you believe your account has been compromised, please contact us immediately.',
          ),
          _PrivacySection(
            number: '6',
            title: 'Your Rights & Choices',
            content:
                'You have the following rights regarding your personal information:\n\n'
                '• Access & Correction: You can view and update your profile information at any time from the Profile section.\n\n'
                '• Notifications: You can manage push notification preferences from your device settings or the in-app Settings screen.\n\n'
                '• Account Deletion: You can delete your account and all associated data from the Settings screen.\n\n'
                '• Data Portability: You may request a copy of your personal data by contacting our support team.\n\n'
                '• Opt-Out: You can opt out of non-essential communications at any time.',
          ),
          _PrivacySection(
            number: '7',
            title: "Children's Privacy",
            content:
                'FitBud is not directed to individuals under the age of 13. We do not knowingly collect personal information from children under 13. '
                'If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information. '
                'If you believe we have collected information from a child, please contact us immediately.',
          ),
          _PrivacySection(
            number: '8',
            title: 'Changes to This Policy',
            content:
                'We may update this Privacy & Security Policy from time to time to reflect changes in our practices or applicable law. '
                'We will notify you of significant changes through the app or by email. '
                'Your continued use of FitBud after the effective date of any changes constitutes your acceptance of the updated policy.\n\n'
                'We encourage you to review this policy periodically to stay informed about how we protect your information.',
          ),
          _PrivacySection(
            number: '9',
            title: 'Contact Us',
            content:
                'If you have any questions, concerns, or requests regarding this Privacy & Security Policy or how we handle your data, please reach out to us:\n\n'
                '• Email: privacy@fitbud.app\n\n'
                '• Support: Available through the Help & Support section in Settings\n\n'
                'We are committed to resolving any concerns promptly and transparently.',
          ),
          const SizedBox(height: 12),
          _LastUpdatedFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PrivacyHeader extends StatelessWidget {
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
                  Icons.shield_outlined,
                  color: XColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Your Privacy Matters',
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
            'At FitBud, we are committed to protecting your personal information and being transparent about how we use it. '
            'This policy explains what data we collect, how we use it, and the choices you have.',
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

class _PrivacySection extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _PrivacySection({
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
