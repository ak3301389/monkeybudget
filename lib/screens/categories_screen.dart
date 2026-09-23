import 'package:flutter/material.dart';
import '../models.dart';

class CategoriesScreen extends StatefulWidget {
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<Category> transferCategories;
  final List<SubCategory> transferSubCategories;
  final List<SubCategory> expenseSubCategories;
  final List<SubCategory> incomeSubCategories;
  final Function(Category) onAddExpenseCategory;
  final Function(Category) onAddIncomeCategory;
  final Function(Category) onDeleteExpenseCategory;
  final Function(Category) onDeleteIncomeCategory;
  final Function(Category) onAddTransferCategory;
  final Function(Category) onDeleteTransferCategory;
  final Function(SubCategory)? onAddTransferSubCategory;
  final Function(SubCategory)? onDeleteTransferSubCategory;
  final Function(SubCategory) onAddExpenseSubCategory;
  final Function(SubCategory) onAddIncomeSubCategory;
  final Function(SubCategory) onDeleteExpenseSubCategory;
  final Function(SubCategory) onDeleteIncomeSubCategory;
  final List<Map<String, dynamic>> categoryIcons;
  
  const CategoriesScreen({
    Key? key,
    required this.expenseCategories,
    required this.incomeCategories,
	required this.transferCategories,
	required this.transferSubCategories,
    required this.expenseSubCategories,
    required this.incomeSubCategories,
    required this.onAddExpenseCategory,
    required this.onAddIncomeCategory,
    required this.onDeleteExpenseCategory,
    required this.onDeleteIncomeCategory,
	required this.onAddTransferCategory,
    required this.onDeleteTransferCategory,
	this.onAddTransferSubCategory,
    this.onDeleteTransferSubCategory,
    required this.onAddExpenseSubCategory,
    required this.onAddIncomeSubCategory,
    required this.onDeleteExpenseSubCategory,
    required this.onDeleteIncomeSubCategory,
    required this.categoryIcons,
  }) : super(key: key);
  
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool showExpense = true;
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Расходы'),
              Tab(text: 'Доходы'),
              Tab(text: 'Переводы'),
            ],
            onTap: (index) {
              setState(() {
                showExpense = index == 0;
              });
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCategoryList(widget.expenseCategories, widget.expenseSubCategories, true),
                _buildCategoryList(widget.incomeCategories, widget.incomeSubCategories, false),
                _buildTransferCategoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildCategoryList(List<Category> categories, List<SubCategory> subCategories, bool isExpense) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        for (var category in categories)
          Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getColorFromHex(category.color),
                child: Icon(category.icon, color: Colors.white, size: 20),
              ),
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.teal),
                    onPressed: () => _showAddSubCategoryDialog(category, isExpense),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteCategory(category, isExpense),
                  ),
                ],
              ),
              children: [
                for (var sub in subCategories.where((s) => s.parentName == category.name))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorFromHex(category.color).withOpacity(0.3),
                      child: Icon(sub.icon, size: 16, color: _getColorFromHex(category.color)),
                    ),
                    title: Text(sub.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _confirmDeleteSubCategory(sub, isExpense),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddCategoryDialog(isExpense),
          icon: Icon(Icons.add),
          label: Text('Добавить категорию'),
        ),
      ],
    );
  }
  
  void _showAddCategoryDialog(bool isExpense) {
    final nameController = TextEditingController();
    String selectedColor = '#607D8B';
    IconData selectedIcon = Icons.category;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Новая категория'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 16),
                    Text('Иконка:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: widget.categoryIcons.map((iconData) {
                        final icon = iconData['icon'] as IconData;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? _getColorFromHex(selectedColor)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: selectedIcon == icon
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: selectedIcon == icon ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text('Цвет:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['#607D8B', '#FF5722', '#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#E91E63', '#795548', '#3F51B5', '#009688', '#8BC34A', '#FFC107', '#00BCD4', '#673AB7', '#F44336', '#CDDC39'].map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorFromHex(color),
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    
                    final category = Category(name, selectedIcon, selectedColor);
                    if (isExpense) {
                      widget.onAddExpenseCategory(category);
                    } else {
                      widget.onAddIncomeCategory(category);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showAddSubCategoryDialog(Category category, bool isExpense) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Новая подкатегория'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                final subCategory = SubCategory(name, category.name, category.icon);
                if (isExpense) {
                  widget.onAddExpenseSubCategory(subCategory);
                } else {
                  widget.onAddIncomeSubCategory(subCategory);
                }
                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
  
  Future<bool> _confirmDeleteCategory(Category category, bool isExpense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить категорию?'),
          content: Text('${category.name}\nВсе подкатегории также будут удалены.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      if (isExpense) {
        widget.onDeleteExpenseCategory(category);
      } else {
        widget.onDeleteIncomeCategory(category);
      }
    }
    return result ?? false;
  }
  
  Future<bool> _confirmDeleteSubCategory(SubCategory subCategory, bool isExpense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить подкатегорию?'),
          content: Text(subCategory.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      if (isExpense) {
        widget.onDeleteExpenseSubCategory(subCategory);
      } else {
        widget.onDeleteIncomeSubCategory(subCategory);
      }
    }
    return result ?? false;
  }
    Widget _buildTransferCategoryList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        for (var category in widget.transferCategories)
          Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getColorFromHex(category.color),
                child: Icon(category.icon, color: Colors.white, size: 20),
              ),
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.teal),
                    onPressed: () => _showAddTransferSubCategoryDialog(category),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Удалить категорию?'),
                            content: Text(category.name),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
                              ElevatedButton(
                                onPressed: () {
                                  widget.onDeleteTransferCategory(category);
                                  Navigator.pop(context);
                                },
                                child: Text('Удалить', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              children: [
                for (var sub in widget.transferSubCategories.where((s) => s.parentName == category.name))
                  ListTile(
                    leading: Icon(Icons.subdirectory_arrow_right),
                    title: Text(sub.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () {
                        widget.onDeleteTransferSubCategory?.call(sub);
                      },
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddTransferCategoryDialog(),
          icon: Icon(Icons.add),
          label: Text('Добавить категорию'),
        ),
      ],
    );
  }

  void _showAddTransferSubCategoryDialog(Category category) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Подкатегория для "${category.name}"'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Название'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                widget.onAddTransferSubCategory?.call(SubCategory(name, category.name, category.icon));
                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransferCategoryDialog() {
    final nameController = TextEditingController();
    String selectedColor = '#2196F3';
    IconData selectedIcon = Icons.swap_horiz;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Новая категория переводов'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Название'),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336'].map((color) {
                      return InkWell(
                        onTap: () {
                          setState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getColorFromHex(color),
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    widget.onAddTransferCategory(Category(name, selectedIcon, selectedColor));
                    Navigator.pop(context);
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}