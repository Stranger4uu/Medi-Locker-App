import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../profile/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditSheet(context, uid),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: Text('Profile not found'));
                }
                final user = UserModel.fromFirestore(snap.data!);
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _InfoCard(
                      title: 'Personal Details',
                      items: [
                        _InfoRow(icon: Icons.badge_outlined, label: 'Name', value: user.name),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date of Birth',
                          value: user.dob != null ? '${user.dob!.day}/${user.dob!.month}/${user.dob!.year}' : '-',
                        ),
                        _InfoRow(icon: Icons.wc_outlined, label: 'Gender', value: user.gender.isNotEmpty ? user.gender : '-'),
                        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone?.isNotEmpty == true ? user.phone! : '-'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'Health Details',
                      items: [
                        _InfoRow(icon: Icons.bloodtype_outlined, label: 'Blood Group', value: user.bloodGroup.isNotEmpty ? user.bloodGroup : '-'),
                        _InfoRow(icon: Icons.warning_amber_outlined, label: 'Allergies', value: user.allergies.isNotEmpty ? user.allergies.join(', ') : 'None'),
                        _InfoRow(icon: Icons.monitor_heart_outlined, label: 'Conditions', value: user.chronicConditions.isNotEmpty ? user.chronicConditions.join(', ') : 'None'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'App',
                      items: [
                        _ActionRow(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),
                        _ActionRow(icon: Icons.description_outlined, label: 'Terms & Privacy Policy', onTap: () => _showTerms(context)),
                        const _ActionRow(
                          icon: Icons.info_outline,
                          label: 'App Version',
                          trailing: Text('1.0.0', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _confirmLogout(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: ctrl,
            children: const [
              Text('Terms & Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(
                'Medical Disclaimer\n\n'
                'Cura AI is not a substitute for professional medical advice, diagnosis, or treatment. '
                'Always seek advice from a qualified healthcare provider for any medical questions.\n\n'
                'Data Privacy\n\n'
                'Your health data is stored securely in Firebase and is only accessible by you. '
                'We do not share your data with any third parties without your consent.\n\n'
                'Data Security\n\n'
                'All uploaded files are encrypted. Your account is protected by Firebase Authentication.\n\n'
                'User Responsibilities\n\n'
                'You are responsible for the accuracy of information you upload. '
                'This app is intended for users aged 18 and above.\n\n'
                'Third-Party Services\n\n'
                'This app uses Google Firebase and Google Gemini AI services.',
                style: TextStyle(fontSize: 14, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, String? uid) {
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(uid: uid),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ActionRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const SizedBox(),
            Icon(icon, size: 18, color: AppColors.textSecondaryLight),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String uid;
  const _EditProfileSheet({required this.uid});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (!mounted) return;
    final d = doc.data() ?? {};
    _firstCtrl.text = d['first_name'] ?? '';
    _lastCtrl.text = d['last_name'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_firstCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final first = _firstCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'first_name': first,
        'last_name': last,
        'name': '$first $last',
        'phone': _phoneCtrl.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _loaded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(controller: _firstCtrl, decoration: const InputDecoration(labelText: 'First name')),
                const SizedBox(height: 12),
                TextFormField(controller: _lastCtrl, decoration: const InputDecoration(labelText: 'Last name')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
