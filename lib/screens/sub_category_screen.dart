import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import '../models/sub_category.dart';

class SubCategoryScreen extends StatefulWidget {
  final Category category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  late Future<List<SubCategory>> _subCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSubCategories();
  }

  void _refreshSubCategories() {
    setState(() {
      _subCategoriesFuture = _getSubCategories();
    });
  }

  Future<List<SubCategory>> _getSubCategories() async {
    final dataList = await DBHelper.getDataWhere('sub_categories', 'categoryId = ?', [widget.category.id]);
    return dataList.map((item) => SubCategory.fromMap(item)).toList();
  }

  void _showSubCategoryDialog({SubCategory? subCategory}) {
    final nameController = TextEditingController(text: subCategory?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subCategory == null ? 'Add Sub-Category' : 'Edit Sub-Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Sub-Category Name'),
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
                if (subCategory == null) {
                  await DBHelper.insert('sub_categories', {'categoryId': widget.category.id, 'name': name});
                } else {
                  await DBHelper.update('sub_categories', {'name': name}, subCategory.id!);
                }
                Navigator.of(context).pop();
                _refreshSubCategories();
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
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSubCategoryDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<SubCategory>>(
        future: _subCategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sub-categories yet. Add one!'));
          }

          final subCategories = snapshot.data!;
          return ListView.builder(
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCategory = subCategories[index];
              return ListTile(
                title: Text(subCategory.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showSubCategoryDialog(subCategory: subCategory),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await DBHelper.delete('sub_categories', subCategory.id!);
                        _refreshSubCategories();
                      },
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
}
