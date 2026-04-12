import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Medi Locker Privacy Policy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _PolicySection(
            title: '1. What We Store',
            body:
                'We store your account details, profile information, medical report metadata, uploaded files, and Cura chat history in Firebase services tied to your account.',
          ),
          _PolicySection(
            title: '2. How Data Is Used',
            body:
                'Your data is used to show your records inside the app, personalize health guidance, and support core app features such as uploads, notifications, and AI chat.',
          ),
          _PolicySection(
            title: '3. AI Disclaimer',
            body:
                'Cura AI is an assistant only. It is not a replacement for a licensed doctor, emergency services, diagnosis, or treatment.',
          ),
          _PolicySection(
            title: '4. File Security',
            body:
                'Uploaded reports are stored in user-specific cloud storage paths. Encrypted upload support exists in the app, with a safe fallback when encryption fails during testing.',
          ),
          _PolicySection(
            title: '5. Third-Party Services',
            body:
                'The app uses Firebase services and may use Gemini-backed AI through a deployed Cloud Function once configured.',
          ),
          _PolicySection(
            title: '6. Your Control',
            body:
                'You can update your profile, sign out, and delete uploaded reports from the app. Full account deletion/export tooling can be added in a later release.',
          ),
          SizedBox(height: 16),
          Text(
            'For production release, you should also host this policy on a public web page and link that same URL in your website and GitHub release notes.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
