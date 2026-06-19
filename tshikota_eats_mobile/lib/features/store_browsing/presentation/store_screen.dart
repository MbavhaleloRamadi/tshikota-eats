import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';

class StoreScreen extends StatelessWidget {
  final String slug;
  const StoreScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .where('slug', isEqualTo: slug)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(color: TshikotaTheme.royalRed),
            ),
          );
        }

        final bizData =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final businessId = snapshot.data!.docs.first.id;

        return Scaffold(
          backgroundColor: TshikotaTheme.bgPrimary,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: (bizData['bannerURL'] ?? '').toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: bizData['bannerURL'],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: TshikotaTheme.royalRed.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TshikotaTheme.royalRed.withValues(alpha: 0.8),
                                TshikotaTheme.burgundy,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: TshikotaTheme.bgSecondary,
                              child:
                                  (bizData['logoURL'] ?? '')
                                      .toString()
                                      .isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: bizData['logoURL'],
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.storefront,
                                      color: TshikotaTheme.textMuted,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bizData['name'] ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: TshikotaTheme.gold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(bizData['averageRating'] ?? 0).toStringAsFixed(1)} (${bizData['totalReviews'] ?? 0} reviews)',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (bizData['isOpen'] == true)
                                  ? TshikotaTheme.success.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (bizData['isOpen'] == true) ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: (bizData['isOpen'] == true)
                                    ? TshikotaTheme.success
                                    : TshikotaTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((bizData['description'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          bizData['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Menu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('menus')
                    .doc(businessId)
                    .collection('items')
                    .where('isActive', isEqualTo: true)
                    .orderBy('sortOrder')
                    .snapshots(),
                builder: (context, menuSnapshot) {
                  if (!menuSnapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: TshikotaTheme.royalRed,
                          ),
                        ),
                      ),
                    );
                  }

                  final items = menuSnapshot.data!.docs;

                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No menu items yet'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((_, i) {
                        final item = items[i].data() as Map<String, dynamic>;
                        return _MenuItemCard(
                          name: item['name'] ?? '',
                          description: item['description'] ?? '',
                          price: item['price'] ?? 0,
                          imageURL: item['imageURL'] ?? '',
                          isAvailable: item['isAvailable'] ?? true,
                          onAddToCart: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['name']} added to cart!'),
                                backgroundColor: TshikotaTheme.royalRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      }, childCount: items.length),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final String name, description, imageURL;
  final int price;
  final bool isAvailable;
  final VoidCallback onAddToCart;

  const _MenuItemCard({
    required this.name,
    required this.description,
    required this.price,
    required this.imageURL,
    required this.isAvailable,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TshikotaTheme.textPrimary,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TshikotaTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      formatZAR(price),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: TshikotaTheme.royalRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: TshikotaTheme.bgSecondary,
                      child: imageURL.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageURL,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.fastfood_outlined,
                              color: TshikotaTheme.textMuted,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isAvailable)
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: TshikotaTheme.royalRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        color: TshikotaTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
