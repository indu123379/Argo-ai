// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'auth/login_screen.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exists = snap.data!.exists;
          final data = exists ? (snap.data!.data() as Map<String, dynamic>) : <String, dynamic>{};
          
          final name = data['name'] ?? user?.displayName ?? 'Farmer';
          final email = data['email'] ?? user?.email ?? '';
          final phone = data['phone'] ?? 'Not added';
          final location = data['location'] ?? 'Not set';
          final totalScans = data['totalScans'] ?? 0;
          final crops = List<String>.from(data['mainCrops'] ?? []);
          final joined = data['joinedAt'] != null
              ? DateFormat('MMM yyyy').format((data['joinedAt'] as dynamic).toDate())
              : 'Recently';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium Header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppTheme.primaryGreen,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.language, color: Colors.white),
                    onSelected: (code) {
                      context.read<LanguageProvider>().changeLanguage(code);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'en', child: Text('English')),
                      const PopupMenuItem(value: 'hi', child: Text('हिन्दी')),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Profile Identity ───────────────────────────────────
                      Text(name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 24),

                      // ── Stats Section ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatBox(
                                value: '$totalScans',
                                label: 'Scans',
                                icon: Icons.qr_code_scanner,
                                color: Colors.blue),
                            _VerticalDivider(),
                            _StatBox(
                                value: crops.isEmpty ? '0' : '${crops.length}',
                                label: 'Crops',
                                icon: Icons.grass,
                                color: Colors.green),
                            _VerticalDivider(),
                            _StatBox(
                                value: joined,
                                label: 'Joined',
                                icon: Icons.calendar_today,
                                color: Colors.orange),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // ── Details Card ──────────────────────────────────────
                      _SectionTitle('Account Details'),
                      const SizedBox(height: 12),
                      _ProfileInfoTile(
                        icon: Icons.phone_android_rounded,
                        label: 'Phone Number',
                        value: phone,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        value: location,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.eco_rounded,
                        label: 'Main Crops',
                        value: crops.isNotEmpty ? crops.join(', ') : 'Not defined',
                      ),

                      const SizedBox(height: 32),

                      // ── Actions ──────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditDialog(context, data),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(l10n.updateProfile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthService>().logout();
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final locationCtrl = TextEditingController(text: data['location'] ?? '');
    final cropsCtrl = TextEditingController(text: (data['mainCrops'] as List?)?.join(', ') ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            left: 32,
            right: 32,
            top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: 'Village / District',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cropsCtrl,
              decoration: InputDecoration(
                labelText: 'Main Crops',
                hintText: 'Rice, Wheat, ...',
                prefixIcon: const Icon(Icons.grass),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  final crops = cropsCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  await FirebaseFirestore.instance.collection('farmers').doc(uid).set({
                    'phone': phoneCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'mainCrops': crops,
                  }, SetOptions(merge: true));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileInfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      );
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        width: 1,
        color: Colors.grey.shade200,
      );
}
