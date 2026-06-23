import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/theme.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  String? _businessId;
  Map<String, dynamic>? _business;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdTokenResult();
      final bizId = token.claims?['businessId'] as String?;
      if (bizId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(bizId)
            .get();
        setState(() {
          _businessId = bizId;
          _business = doc.data();
        });
      }
    }
  }

  Future<void> _toggleOpen(bool isOpen) async {
    if (_businessId == null) return;
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .update({'isOpen': isOpen, 'updatedAt': FieldValue.serverTimestamp()});
    setState(() => _business?['isOpen'] = isOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TshikotaTheme.bgPrimary,
      appBar: AppBar(title: const Text('Settings')),
      body: _business == null
          ? const Center(
              child: CircularProgressIndicator(
                color: TshikotaTheme.forestGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Store Info Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _business?['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _business?['category'] ?? '',
                          style: const TextStyle(
                            color: TshikotaTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _business?['contactEmail'] ?? '',
                          style: const TextStyle(
                            color: TshikotaTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _business?['contactPhone'] ?? '',
                          style: const TextStyle(
                            color: TshikotaTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Open/Closed Toggle ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_business?['isOpen'] == true)
                                  ? 'Currently Open'
                                  : 'Currently Closed',
                              style: TextStyle(
                                color: (_business?['isOpen'] == true)
                                    ? TshikotaTheme.success
                                    : TshikotaTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _business?['isOpen'] == true,
                          onChanged: _toggleOpen,
                          activeThumbColor: TshikotaTheme.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Store Link ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Store Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TshikotaTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _business?['storeLink'] ??
                                'https://tshikotaeats.co.za/store/${_business?['slug']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: TshikotaTheme.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final link =
                                  _business?['storeLink'] ??
                                  'https://tshikotaeats.co.za/store/${_business?['slug']}';
                              Share.share(
                                'Check out my store on Tshikota Eats! $link',
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share Store Link'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Account Info ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: TshikotaTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: TshikotaTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  'No name',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Logout Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TshikotaTheme.error,
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TshikotaTheme.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
