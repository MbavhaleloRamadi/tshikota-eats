import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/theme.dart';
import '../../utils/currency_formatter.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdTokenResult();
      setState(() => _businessId = token.claims?['businessId'] as String?);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? TshikotaTheme.error : TshikotaTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TshikotaTheme.royalRed),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TshikotaTheme.bgPrimary,
      appBar: AppBar(title: const Text('Menu Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: TshikotaTheme.royalRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menus')
            .doc(_businessId)
            .collection('items')
            .orderBy('sortOrder')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: TshikotaTheme.royalRed),
            );
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.restaurant_menu_outlined,
                    size: 64,
                    color: TshikotaTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No menu items yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first item',
                    style: TextStyle(color: TshikotaTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i].data() as Map<String, dynamic>;
              final itemId = items[i].id;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    // Item info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              // Available/Unavailable badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (item['isAvailable'] == true)
                                      ? TshikotaTheme.success.withValues(
                                          alpha: 0.1,
                                        )
                                      : TshikotaTheme.error.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (item['isAvailable'] == true)
                                      ? 'Available'
                                      : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: (item['isAvailable'] == true)
                                        ? TshikotaTheme.success
                                        : TshikotaTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((item['description'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TshikotaTheme.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatZAR(item['price'] ?? 0),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: TshikotaTheme.royalRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item['category'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TshikotaTheme.textMuted,
                                ),
                              ),
                              if ((item['tags'] as List?)?.contains(
                                    'special',
                                  ) ==
                                  true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TshikotaTheme.gold.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '⭐ SPECIAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: TshikotaTheme.burgundy,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Column(
                      children: [
                        // Toggle availability
                        IconButton(
                          icon: Icon(
                            (item['isAvailable'] == true)
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: TshikotaTheme.textMuted,
                            size: 22,
                          ),
                          onPressed: () => _toggleAvailability(
                            itemId,
                            item['isAvailable'] == true,
                          ),
                          tooltip: 'Toggle availability',
                        ),
                        // Edit
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: TshikotaTheme.royalRed,
                            size: 22,
                          ),
                          onPressed: () => _showAddEditDialog(items[i]),
                          tooltip: 'Edit item',
                        ),
                        // Delete
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: TshikotaTheme.error,
                            size: 22,
                          ),
                          onPressed: () =>
                              _deleteItem(itemId, item['name'] ?? ''),
                          tooltip: 'Delete item',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleAvailability(String itemId, bool currentValue) async {
    await FirebaseFirestore.instance
        .collection('menus')
        .doc(_businessId)
        .collection('items')
        .doc(itemId)
        .update({
          'isAvailable': !currentValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    _showSnack(
      !currentValue ? 'Item is now available' : 'Item marked as unavailable',
    );
  }

  Future<void> _deleteItem(String itemId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$name"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(_businessId)
          .collection('items')
          .doc(itemId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _showSnack('"$name" deleted');
    }
  }

  void _showAddEditDialog(DocumentSnapshot? existingItem) {
    final isEditing = existingItem != null;
    final data = isEditing ? existingItem.data() as Map<String, dynamic> : {};

    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final descCtrl = TextEditingController(text: data['description'] ?? '');
    final priceCtrl = TextEditingController(
      text: isEditing ? ((data['price'] ?? 0) / 100).toStringAsFixed(2) : '',
    );
    final prepTimeCtrl = TextEditingController(
      text: (data['preparationTime'] ?? '').toString(),
    );
    String category = data['category'] ?? 'Main';
    bool isSpecial = (data['tags'] as List?)?.contains('special') == true;
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
                    Text(
                      isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Item Name (e.g., Pap & Mogodu)',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Price (e.g., 55.00)',
                        prefixText: 'R ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(hintText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Main', child: Text('Main')),
                        DropdownMenuItem(value: 'Side', child: Text('Side')),
                        DropdownMenuItem(value: 'Drink', child: Text('Drink')),
                        DropdownMenuItem(
                          value: 'Dessert',
                          child: Text('Dessert'),
                        ),
                        DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                        DropdownMenuItem(
                          value: 'Fruit Box',
                          child: Text('Fruit Box'),
                        ),
                        DropdownMenuItem(
                          value: 'Veggie Box',
                          child: Text('Veggie Box'),
                        ),
                        DropdownMenuItem(value: 'Combo', child: Text('Combo')),
                      ],
                      onChanged: (val) => setModalState(() => category = val!),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: prepTimeCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Preparation Time (minutes)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Special toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: TshikotaTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('⭐', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'Mark as Special',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Switch(
                            value: isSpecial,
                            onChanged: (val) =>
                                setModalState(() => isSpecial = val),
                            activeThumbColor: TshikotaTheme.gold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty ||
                                    priceCtrl.text.trim().isEmpty) {
                                  _showSnack(
                                    'Name and price are required',
                                    isError: true,
                                  );
                                  return;
                                }

                                final price =
                                    (double.tryParse(priceCtrl.text.trim()) ??
                                        0) *
                                    100;
                                if (price <= 0) {
                                  _showSnack(
                                    'Enter a valid price',
                                    isError: true,
                                  );
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                try {
                                  final tags = <String>[];
                                  if (isSpecial) tags.add('special');

                                  final itemData = {
                                    'name': nameCtrl.text.trim(),
                                    'description': descCtrl.text.trim(),
                                    'price': price.round(),
                                    'category': category,
                                    'tags': tags,
                                    'preparationTime':
                                        int.tryParse(
                                          prepTimeCtrl.text.trim(),
                                        ) ??
                                        15,
                                    'isAvailable': true,
                                    'isActive': true,
                                    'businessId': _businessId,
                                    'imageURL': '',
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };

                                  final itemsRef = FirebaseFirestore.instance
                                      .collection('menus')
                                      .doc(_businessId)
                                      .collection('items');

                                  if (isEditing) {
                                    await itemsRef
                                        .doc(existingItem.id)
                                        .update(itemData);
                                  } else {
                                    // Get next sort order
                                    final existing = await itemsRef.get();
                                    itemData['sortOrder'] = existing.size + 1;
                                    itemData['itemId'] = '';
                                    itemData['createdAt'] =
                                        FieldValue.serverTimestamp();

                                    final newDoc = await itemsRef.add(itemData);
                                    await newDoc.update({'itemId': newDoc.id});
                                  }

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _showSnack(
                                    isEditing
                                        ? '"${nameCtrl.text}" updated!'
                                        : '"${nameCtrl.text}" added to menu!',
                                  );
                                } catch (e) {
                                  setModalState(() => isLoading = false);
                                  _showSnack('Error: $e', isError: true);
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEditing ? 'Update Item' : 'Add to Menu'),
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
