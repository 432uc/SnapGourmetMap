import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/photo_spot.dart';

class EditSpotScreen extends StatefulWidget {
  final PhotoSpot photoSpot;

  const EditSpotScreen({super.key, required this.photoSpot});

  @override
  State<EditSpotScreen> createState() => _EditSpotScreenState();
}

class _EditSpotScreenState extends State<EditSpotScreen> {
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoriesData = await DBHelper.getData('categories');
    setState(() {
      _categories = categoriesData.map((item) => Category.fromMap(item)).toList();
    });
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final subCategoriesData = await DBHelper.getDataWhere('sub_categories', 'categoryId = ?', [categoryId]);
    setState(() {
      _subCategories = subCategoriesData.map((item) => SubCategory.fromMap(item)).toList();
    });
  }

  void _onCategoryChanged(Category? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedCategory = newCategory;
        _selectedSubCategory = null; // Reset sub-category
        _subCategories = [];
        _loadSubCategories(newCategory.id!);
      });
    }
  }

  void _saveSpot() async {
    final spotToUpdate = PhotoSpot(
      id: widget.photoSpot.id,
      latitude: widget.photoSpot.latitude,
      longitude: widget.photoSpot.longitude,
      imagePath: widget.photoSpot.imagePath,
      categoryId: _selectedCategory?.id,
      subCategoryId: _selectedSubCategory?.id,
    );
    
    // Since we are creating a new spot, we insert it.
    // The id will be auto-generated.
    final newId = await DBHelper.insert('photo_spots', spotToUpdate.toMap());

    // Return the final spot with its new ID.
    final finalSpot = PhotoSpot(
        id: newId,
        latitude: spotToUpdate.latitude,
        longitude: spotToUpdate.longitude,
        imagePath: spotToUpdate.imagePath,
        categoryId: spotToUpdate.categoryId,
        subCategoryId: spotToUpdate.subCategoryId
    );

    if (mounted) {
      Navigator.of(context).pop(finalSpot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Spot Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSpot,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.file(File(widget.photoSpot.imagePath)),
            const SizedBox(height: 20),
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              hint: const Text('Select Genre'),
              items: _categories.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: _onCategoryChanged,
              decoration: const InputDecoration(labelText: 'Genre'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<SubCategory>(
              value: _selectedSubCategory,
              hint: const Text('Select Taste/Details'),
              items: _subCategories.map((SubCategory subCategory) {
                return DropdownMenuItem<SubCategory>(
                  value: subCategory,
                  child: Text(subCategory.name),
                );
              }).toList(),
              onChanged: (SubCategory? newSubCategory) {
                setState(() {
                  _selectedSubCategory = newSubCategory;
                });
              },
              decoration: const InputDecoration(labelText: 'Taste/Details'),
            ),
          ],
        ),
      ),
    );
  }
}
