import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spendify/utils/utils.dart';

class CategoriesChips extends StatelessWidget {
  final List<CategoriesModel> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onChanged;

  const CategoriesChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0, // Adjust spacing between chips as needed
      children: categories.map((category) {
        return ChoiceChip(
          selectedColor: AppColor.primaryExtraSoft,
          backgroundColor: Colors.white,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                category.image,
                width: 16, // Adjust icon size as needed
                height: 16, // Adjust icon size as needed
              ),
              horizontalSpace(4),
              Text(category.category),
            ],
          ),
          selected: selectedCategory == category.category,
          onSelected: (selected) {
            if (onChanged != null) {
              onChanged!(selected ? category.category : null);
            }
          },
        );
      }).toList(),
    );
  }
}
