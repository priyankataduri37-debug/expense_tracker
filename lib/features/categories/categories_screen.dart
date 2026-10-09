import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.customCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: categories.isEmpty
          ? const Center(
              child: Text(
                'No custom categories yet.\nTap Add category to create one.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = category.colorValue == null
                    ? Theme.of(context).colorScheme.primary
                    : Color(category.colorValue!);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(iconFor(category.iconKey), color: color),
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    category.type == TxType.expense ? 'Expense' : 'Income',
                  ),
                  trailing: IconButton(
                    tooltip: 'Archive category',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Archive category?'),
                          content: Text(
                            '“${category.name}” will no longer appear '
                            'in the category picker. Existing transactions '
                            'will be preserved.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Archive'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true || !context.mounted) return;

                      try {
                        await context.read<CategoryProvider>().archiveCategory(
                          category.id,
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not archive: $error')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    var type = TxType.expense;
    var iconKey = 'shopping';
    var colorValue = Colors.teal.toARGB32();

    const iconOptions = <String, IconData>{
      'shopping': Icons.shopping_bag_outlined,
      'food': Icons.restaurant_outlined,
      'transport': Icons.directions_car_outlined,
      'home': Icons.home_outlined,
      'health': Icons.medical_services_outlined,
      'education': Icons.school_outlined,
      'travel': Icons.flight_outlined,
      'salary': Icons.work_outline,
      'savings': Icons.savings_outlined,
      'gift': Icons.card_giftcard_outlined,
      'other': Icons.category_outlined,
    };

    const colors = <Color>[
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.red,
      Colors.indigo,
    ];

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New category'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'e.g. Pet care',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a category name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TxType>(
                      segments: const [
                        ButtonSegment(
                          value: TxType.expense,
                          label: Text('Expense'),
                        ),
                        ButtonSegment(
                          value: TxType.income,
                          label: Text('Income'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (selected) {
                        setDialogState(() => type = selected.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Choose an icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in iconOptions.entries)
                          ChoiceChip(
                            label: Icon(entry.value, size: 20),
                            selected: iconKey == entry.key,
                            onSelected: (_) =>
                                setDialogState(() => iconKey = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Choose a color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final color in colors)
                          GestureDetector(
                            onTap: () => setDialogState(
                              () => colorValue = color.toARGB32(),
                            ),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: color,
                              child: colorValue == color.toARGB32()
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );

      if (result != true || !context.mounted) return;

      final userId = context.read<AuthProvider>().userId;

      await context.read<CategoryProvider>().createCustomCategory(
        userId: userId,
        name: nameController.text,
        type: type,
        iconKey: iconKey,
        colorValue: colorValue,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category created')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create category: $error')),
      );
    } finally {
      nameController.dispose();
    }
  }
}
