import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../utils/currency_formatter.dart';

class DevDashboardScreen extends StatefulWidget {
  const DevDashboardScreen({super.key});

  @override
  State<DevDashboardScreen> createState() => _DevDashboardScreenState();
}

class _DevDashboardScreenState extends State<DevDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? TshikotaTheme.error : TshikotaTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TshikotaTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
        backgroundColor: TshikotaTheme.royalRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TshikotaTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.store), text: 'Businesses'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _BusinessesTab(showSnack: _showSnack),
          _UsersTab(showSnack: _showSnack),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 1: OVERVIEW
// ═══════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('analytics')
          .doc('platform')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform Overview',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _MetricCard(
                    title: 'Total Users',
                    value: '${data['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    color: TshikotaTheme.royalRed,
                  ),
                  _MetricCard(
                    title: 'Businesses',
                    value: '${data['totalBusinesses'] ?? 0}',
                    icon: Icons.store,
                    color: TshikotaTheme.burgundy,
                  ),
                  _MetricCard(
                    title: 'Total Orders',
                    value: '${data['totalOrders'] ?? 0}',
                    icon: Icons.receipt_long,
                    color: TshikotaTheme.gold,
                  ),
                  _MetricCard(
                    title: 'Revenue',
                    value: formatZAR((data['totalRevenue'] ?? 0) is int
                        ? data['totalRevenue']
                        : 0),
                    icon: Icons.attach_money,
                    color: TshikotaTheme.success,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: TshikotaTheme.textMuted)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 2: BUSINESSES
// ═══════════════════════════════════════════════

class _BusinessesTab extends StatelessWidget {
  final void Function(String, {bool isError}) showSnack;
  const _BusinessesTab({required this.showSnack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Create button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateBusinessDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create New Business'),
            ),
          ),
        ),

        // Business list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: TshikotaTheme.royalRed));
              }

              final businesses = snapshot.data!.docs;

              if (businesses.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined,
                          size: 64, color: TshikotaTheme.textMuted),
                      SizedBox(height: 16),
                      Text('No businesses yet',
                          style: TextStyle(
                              fontSize: 16, color: TshikotaTheme.textMuted)),
                      SizedBox(height: 8),
                      Text('Create one to get started'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: businesses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final biz = businesses[i].data() as Map<String, dynamic>;
                  final bizId = businesses[i].id;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(biz['name'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (biz['isOpen'] == true)
                                    ? TshikotaTheme.success
                                        .withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (biz['isOpen'] == true) ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: (biz['isOpen'] == true)
                                      ? TshikotaTheme.success
                                      : TshikotaTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Category: ${biz['category'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: TshikotaTheme.textSecondary)),
                        Text('Slug: ${biz['slug'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: TshikotaTheme.textSecondary)),
                        Text('Owner: ${biz['ownerId'] ?? 'Not assigned'}',
                            style: const TextStyle(
                                fontSize: 13, color: TshikotaTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('ID: $bizId',
                            style: const TextStyle(
                                fontSize: 11, color: TshikotaTheme.textMuted)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateBusinessDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'food';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create New Business',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Business Name'),
                      onChanged: (val) {
                        slugCtrl.text = val
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Slug (auto-generated)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(hintText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Food')),
                        DropdownMenuItem(value: 'fruit', child: Text('Fruit')),
                        DropdownMenuItem(
                            value: 'vegetables', child: Text('Vegetables')),
                        DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                      ],
                      onChanged: (val) => setModalState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Contact Phone (+27...)'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Contact Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty ||
                                    slugCtrl.text.trim().isEmpty ||
                                    phoneCtrl.text.trim().isEmpty ||
                                    emailCtrl.text.trim().isEmpty) {
                                  showSnack('All fields are required',
                                      isError: true);
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                try {
                                  final callable = FirebaseFunctions.instance
                                      .httpsCallable('createBusiness');
                                  final result = await callable.call({
                                    'name': nameCtrl.text.trim(),
                                    'slug': slugCtrl.text.trim(),
                                    'category': category,
                                    'description': descCtrl.text.trim(),
                                    'contactPhone': phoneCtrl.text.trim(),
                                    'contactEmail': emailCtrl.text.trim(),
                                    'fulfillmentModes': ['pickup'],
                                  });

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  showSnack(
                                      'Business "${nameCtrl.text}" created! ID: ${result.data['businessId']}');
                                } catch (e) {
                                  setModalState(() => isLoading = false);
                                  showSnack('Error: $e', isError: true);
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('Create Business'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 3: USERS
// ═══════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  final void Function(String, {bool isError}) showSnack;
  const _UsersTab({required this.showSnack});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: TshikotaTheme.royalRed));
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('No users yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final user = users[i].data() as Map<String, dynamic>;
            final uid = users[i].id;
            final role = user['role'] ?? 'buyer';

            Color roleColor = TshikotaTheme.textMuted;
            if (role == 'developer') roleColor = TshikotaTheme.royalRed;
            if (role == 'company') roleColor = TshikotaTheme.burgundy;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    child: Icon(
                      role == 'developer'
                          ? Icons.code
                          : role == 'company'
                              ? Icons.store
                              : Icons.person,
                      color: roleColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['displayName'] ?? 'No Name',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(user['email'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: TshikotaTheme.textSecondary)),
                        Text('UID: $uid',
                            style: const TextStyle(
                                fontSize: 11, color: TshikotaTheme.textMuted)),
                      ],
                    ),
                  ),

                  // Role badge
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: roleColor),
                        ),
                      ),
                      if (role == 'buyer') ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showAssignRoleDialog(
                              context, uid, user['email'] ?? ''),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: TshikotaTheme.royalRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ASSIGN',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignRoleDialog(
      BuildContext context, String targetUid, String email) {
    String? selectedBusinessId;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Assign Company Role',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('User: $email',
                      style:
                          const TextStyle(color: TshikotaTheme.textSecondary)),
                  const SizedBox(height: 20),

                  // Business dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('businesses')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final businesses = snapshot.data!.docs;

                      if (businesses.isEmpty) {
                        return const Text(
                          'No businesses available. Create one first.',
                          style: TextStyle(color: TshikotaTheme.error),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: selectedBusinessId,
                        decoration: const InputDecoration(
                            hintText: 'Select a business'),
                        items: businesses.map((doc) {
                          final biz = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(biz['name'] ?? doc.id),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedBusinessId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading || selectedBusinessId == null
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);

                              try {
                                final callable = FirebaseFunctions.instance
                                    .httpsCallable('assignCompanyRole');
                                await callable.call({
                                  'targetUid': targetUid,
                                  'businessId': selectedBusinessId,
                                });

                                if (ctx.mounted) Navigator.pop(ctx);
                                showSnack('Company role assigned to $email!');
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                showSnack('Error: $e', isError: true);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Assign Company Role'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
