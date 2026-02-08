import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/photo_spot.dart';
import '../models/order_item.dart';

class EditSpotScreen extends StatefulWidget {
  final PhotoSpot photoSpot;

  const EditSpotScreen({super.key, required this.photoSpot});

  @override
  State<EditSpotScreen> createState() => _EditSpotScreenState();
}

class _EditSpotScreenState extends State<EditSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _notesController;
  
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  int? _selectedRating;
  String? _selectedVisitCount;
  List<OrderItem> _orders = [];

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.photoSpot.shopName);
    _notesController = TextEditingController(text: widget.photoSpot.notes);
    _selectedRating = widget.photoSpot.rating;
    _selectedVisitCount = widget.photoSpot.visitCount;
    _orders = List.from(widget.photoSpot.orders); // Create a mutable copy
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadCategories();
    if (widget.photoSpot.categoryId != null && _categories.any((c) => c.id == widget.photoSpot.categoryId)) {
      _selectedCategory = _categories.firstWhere((cat) => cat.id == widget.photoSpot.categoryId);
      await _loadSubCategories(widget.photoSpot.categoryId!);
      if (widget.photoSpot.subCategoryId != null && _subCategories.any((s) => s.id == widget.photoSpot.subCategoryId)) {
        _selectedSubCategory = _subCategories.firstWhere((sub) => sub.id == widget.photoSpot.subCategoryId);
      }
    }
    setState(() => _isLoading = false);
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

  void _addOrderItem() {
    setState(() {
      _orders.add(OrderItem());
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orders.removeAt(index);
    });
  }

  Future<void> _saveSpot() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // Final check for location data before saving.
      if (widget.photoSpot.latitude == null || widget.photoSpot.longitude == null) {
        throw Exception('Latitude or Longitude is invalid.');
      }

      final spotToSave = PhotoSpot(
        id: widget.photoSpot.id,
        latitude: widget.photoSpot.latitude,
        longitude: widget.photoSpot.longitude,
        imagePath: widget.photoSpot.imagePath,
        categoryId: _selectedCategory?.id,
        subCategoryId: _selectedSubCategory?.id,
        shopName: _shopNameController.text,
        rating: _selectedRating,
        visitCount: _selectedVisitCount,
        notes: _notesController.text,
        orders: _orders,
      );

      if (spotToSave.id != null) {
        await DBHelper.update('photo_spots', spotToSave.toMap(), spotToSave.id!);
        if (mounted) Navigator.of(context).pop();
      } else {
        final newId = await DBHelper.insert('photo_spots', spotToSave.toMap());
        if (newId > 0) {
            final results = await DBHelper.getDataWhere('photo_spots', 'id = ?', [newId]);
            if (results.isNotEmpty) {
                 final finalSpot = PhotoSpot.fromMap(results.first);
                 if (mounted) Navigator.of(context).pop(finalSpot);
            } else {
                 throw Exception('Failed to retrieve the newly saved spot.');
            }
        } else {
            throw Exception('Failed to save the spot to the database.');
        }
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving spot: ${e.toString()}'))
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photoSpot.id == null ? 'Add Spot Details' : 'Edit Spot Details'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveSpot)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.file(File(widget.photoSpot.imagePath)),
                    const SizedBox(height: 20),
                    TextFormField(controller: _shopNameController, maxLength: 50, decoration: const InputDecoration(labelText: 'Shop Name')),
                    DropdownButtonFormField<int>(value: _selectedRating, hint: const Text('Rating'), items: [1, 2, 3, 4, 5].map((r) => DropdownMenuItem(value: r, child: Text('★' * r))).toList(), onChanged: (val) => setState(() => _selectedRating = val)),
                    DropdownButtonFormField<String>(value: _selectedVisitCount, hint: const Text('Visit Count'), items: ['1 time', '2 times', '3+ times'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (val) => setState(() => _selectedVisitCount = val)),
                    DropdownButtonFormField<Category>(value: _selectedCategory, hint: const Text('Select Genre'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: _onCategoryChanged, decoration: const InputDecoration(labelText: 'Genre')),
                    DropdownButtonFormField<SubCategory>(value: _selectedSubCategory, hint: const Text('Select Taste/Details'), items: _subCategories.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (val) => setState(() => _selectedSubCategory = val), decoration: const InputDecoration(labelText: 'Taste/Details')),
                    const SizedBox(height: 20),
                    Text('Orders', style: Theme.of(context).textTheme.titleLarge),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(child: TextFormField(initialValue: _orders[index].itemName, decoration: const InputDecoration(labelText: 'Item'), onChanged: (val) => _orders[index].itemName = val)),
                            const SizedBox(width: 8),
                            SizedBox(width: 100, child: TextFormField(initialValue: _orders[index].price?.toString() ?? '', decoration: const InputDecoration(labelText: 'Price', suffixText: 'yen'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (val) => _orders[index].price = int.tryParse(val))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeOrderItem(index)),
                          ],
                        );
                      },
                    ),
                    Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.add_circle), onPressed: _addOrderItem)),
                    TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
                  ],
                ),
              ),
            ),
    );
  }
   @override
  void dispose() {
    _shopNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
