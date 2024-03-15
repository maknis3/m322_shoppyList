import 'package:app/providers/timezone_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/api_service.dart';
import '../utils/helpers/snackbar_helper.dart';

class EditProductForm extends StatefulWidget {
  final String listId;
  final String productId;
  final String initialQuantity;
  final String initialUnit;
  final String initialProductName;
  final VoidCallback onFormSubmit;
  final String creator;
  final String createdAt;
  final String lastEditedAt;

  const EditProductForm({
    super.key,
    required this.listId,
    required this.productId,
    required this.initialQuantity,
    required this.initialUnit,
    required this.initialProductName,
    required this.onFormSubmit,
    required this.creator,
    required this.createdAt,
    required this.lastEditedAt,
  });

  @override
  State<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String? _selectedUnit;
  final ApiService _apiService = ApiService();

  String _formatDateTime(String dateTimeStr, BuildContext context) {
    final timezoneProvider =
        Provider.of<TimezoneProvider>(context, listen: false);
    final String timezoneId = timezoneProvider.timezone;

    final DateFormat formatter = DateFormat('dd.MM.yyyy HH:mm');
    final location = tz.getLocation(timezoneId);
    final DateTime dateTime = DateTime.parse(dateTimeStr);
    final tz.TZDateTime zonedTime = tz.TZDateTime.from(dateTime, location);

    return formatter.format(zonedTime);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProductName);
    _quantityController = TextEditingController(text: widget.initialQuantity);
    _selectedUnit = widget.initialUnit;
  }

  void _submitForm() async {
    bool success = await _apiService.updateProductDetails(
      widget.listId,
      widget.productId,
      _nameController.text,
      _quantityController.text,
      _selectedUnit!,
    );

    if (success) {
      Navigator.of(context).pop();
      SnackbarHelper.showSnackBar('Product updated successfully');
      widget.onFormSubmit();
    } else {
      SnackbarHelper.showSnackBar('Failed to update product', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUnit = newValue;
                });
              },
              items: <String>['g', 'kg', 'dL', 'L', 'Stk.'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 10),
            Text('Creator: ${widget.creator}'),
            Text('Created at: ${_formatDateTime(widget.createdAt, context)}'),
            Text('Last edit: ${_formatDateTime(widget.lastEditedAt, context)}'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitForm,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
