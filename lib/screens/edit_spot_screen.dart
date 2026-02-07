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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadCategories();
    if (widget.photoSpot.categoryId != null) {
      _selectedCategory = _categories.firstWhere((cat) => cat.id == widget.photoSpot.categoryId, orElse: () => _categories.first);
      await _loadSubCategories(widget.photoSpot.categoryId!);
      if (widget.photoSpot.subCategoryId != null) {
        _selectedSubCategory = _subCategories.firstWhere((sub) => sub.id == widget.photoSpot.subCategoryId, orElse: () => _subCategories.first);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final categoriesData = await DBHelper.getData('categories');
    _categories = categoriesData.map((item) => Category.fromMap(item)).toList();
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final subCategoriesData = await DBHelper.getDataWhere('sub_categories', 'categoryId = ?', [categoryId]);
    _subCategories = subCategoriesData.map((item) => SubCategory.fromMap(item)).toList();
  }

  void _onCategoryChanged(Category? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedCategory = newCategory;
        _selectedSubCategory = null;
        _subCategories = [];
        _loadSubCategories(newCategory.id!);
      });
    }
  }

  Future<void> _saveSpot() async {
    final spotWithCategories = PhotoSpot(
      id: widget.photoSpot.id,
      latitude: widget.photoSpot.latitude,
      longitude: widget.photoSpot.longitude,
      imagePath: widget.photoSpot.imagePath,
      categoryId: _selectedCategory?.id,
      subCategoryId: _selectedSubCategory?.id,
    );

    if (spotWithCategories.id != null) {
      // Update existing spot
      await DBHelper.update('photo_spots', spotWithCategories.toMap(), spotWithCategories.id!);
    } else {
      // Insert new spot
      final newId = await DBHelper.insert('photo_spots', spotWithCategories.toMap());
      // Create a final spot object with the new ID to return
      final finalSpot = PhotoSpot.fromMap((await DBHelper.getDataWhere('photo_spots', 'id = ?', [newId])).first);
      if (mounted) {
          Navigator.of(context).pop(finalSpot);
          return; // Exit after popping for new spot
      }
    }
    // For updates, we can just pop. The calling screen will handle refresh.
    if(mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photoSpot.id == null ? 'Add Spot Details' : 'Edit Spot Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSpot,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
