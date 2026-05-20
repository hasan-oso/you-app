import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('privacy_policy_title'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'privacy_intro_title'.tr,
              'privacy_intro_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_data_collection_title'.tr,
              'privacy_data_collection_content'.tr,
            ),
            const SizedBox(height: 16),
            _buildBulletList([
              'privacy_data_personal'.tr,
              'privacy_data_health'.tr,
              'privacy_data_usage'.tr,
              'privacy_data_device'.tr,
            ]),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_data_usage_title'.tr,
              'privacy_data_usage_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_third_party_title'.tr,
              'privacy_third_party_content'.tr,
            ),
            const SizedBox(height: 16),
            _buildBulletList([
              'privacy_third_party_supabase'.tr,
              'privacy_third_party_gemini'.tr,
              'privacy_third_party_admob'.tr,
              'privacy_third_party_google'.tr,
            ]),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_data_security_title'.tr,
              'privacy_data_security_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_user_rights_title'.tr,
              'privacy_user_rights_content'.tr,
            ),
            const SizedBox(height: 16),
            _buildBulletList([
              'privacy_right_access'.tr,
              'privacy_right_correction'.tr,
              'privacy_right_deletion'.tr,
              'privacy_right_export'.tr,
            ]),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_data_retention_title'.tr,
              'privacy_data_retention_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_children_title'.tr,
              'privacy_children_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_changes_title'.tr,
              'privacy_changes_content'.tr,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'privacy_contact_title'.tr,
              'privacy_contact_content'.tr,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'privacy_last_updated'.tr,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• ',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
            ),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
