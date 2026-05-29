import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  final _searchCtrl = TextEditingController();

  final _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.grid_view_rounded},
    {'id': 'food', 'label': 'Food', 'icon': Icons.restaurant},
    {'id': 'fruit', 'label': 'Fruits', 'icon': Icons.apple},
    {'id': 'vegetables', 'label': 'Veggies', 'icon': Icons.eco},
    {'id': 'mixed', 'label': 'Mixed', 'icon': Icons.shopping_basket},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('businesses')
        .where('isActive', isEqualTo: true);

    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    query = query.orderBy('averageRating', descending: true).limit(30);
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TshikotaTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tshikota Eats',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: TshikotaTheme.royalRed,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text('What are you craving today?',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined,
                              size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: TshikotaTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search stores, food, fruits...',
                          prefixIcon: const Icon(Icons.search,
                              color: TshikotaTheme.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedCategory = cat['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TshikotaTheme.royalRed
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? TshikotaTheme.royalRed
                                : TshikotaTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : TshikotaTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : TshikotaTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                if (!snapshot.hasData) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => _StoreCardSkeleton(),
                        childCount: 6,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = _searchCtrl.text.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final tags =
                            (data['tags'] as List?)?.join(' ').toLowerCase() ??
                                '';
                        final query = _searchCtrl.text.toLowerCase();
                        return name.contains(query) || tags.contains(query);
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined,
                              size: 64, color: TshikotaTheme.textMuted),
                          SizedBox(height: 16),
                          Text('No stores found',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('Try a different category or search term',
                              style: TextStyle(color: TshikotaTheme.textMuted)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final data =
                            filteredDocs[i].data() as Map<String, dynamic>;
                        return _StoreCard(
                          name: data['name'] ?? '',
                          category: data['category'] ?? '',
                          logoURL: data['logoURL'] ?? '',
                          rating: (data['averageRating'] ?? 0).toDouble(),
                          reviewCount: data['totalReviews'] ?? 0,
                          isOpen: data['isOpen'] ?? false,
                          onTap: () => context.push('/store/${data['slug']}'),
                        );
                      },
                      childCount: filteredDocs.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String name, category, logoURL;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final VoidCallback onTap;

  const _StoreCard({
    required this.name,
    required this.category,
    required this.logoURL,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    logoURL.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logoURL,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: TshikotaTheme.bgSecondary),
                            errorWidget: (_, __, ___) => Container(
                                color: TshikotaTheme.bgSecondary,
                                child: const Icon(Icons.storefront,
                                    size: 40, color: TshikotaTheme.textMuted)))
                        : Container(
                            color: TshikotaTheme.bgSecondary,
                            child: const Icon(Icons.storefront,
                                size: 40, color: TshikotaTheme.textMuted)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? TshikotaTheme.success
                              : TshikotaTheme.textMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TshikotaTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                      category.isNotEmpty
                          ? category[0].toUpperCase() + category.substring(1)
                          : '',
                      style: const TextStyle(
                          fontSize: 12, color: TshikotaTheme.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: TshikotaTheme.gold),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: TshikotaTheme.textPrimary)),
                      const SizedBox(width: 4),
                      Text('($reviewCount)',
                          style: const TextStyle(
                              fontSize: 12, color: TshikotaTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
