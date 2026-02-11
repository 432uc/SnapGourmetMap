import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import 'sub_category_screen.dart';
import 'export_screen.dart'; // Add this

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = _getCategories();
    });
  }

  Future<List<Category>> _getCategories() async {
    final dataList = await DBHelper.getData('categories');
    return dataList.map((item) => Category.fromMap(item)).toList();
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final name = nameController.text;
              if (name.isNotEmpty) {
                if (category == null) {
                  await DBHelper.insert('categories', {'name': name});
                } else {
                  await DBHelper.update('categories', {'name': name}, category.id!);
                }
                Navigator.of(context).pop();
                _refreshCategories();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final categories = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: Colors.green),
                      title: const Text('Google Sheets Export'),
                      subtitle: const Text('データをスプレッドシートに出力'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExportScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'カテゴリー管理',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (categories.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No categories yet. Add one!')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showCategoryDialog(category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await DBHelper.delete('categories', category.id!);
                                _refreshCategories();
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SubCategoryScreen(category: category),
                            ),
                          );
                        },
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
