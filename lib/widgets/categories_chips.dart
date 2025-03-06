// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:spendify/config/app_color.dart';
// import 'package:spendify/model/categories_model.dart';
// import 'package:spendify/utils/utils.dart';

// class CategoriesChips extends StatelessWidget {
//   final List<CategoriesModel> categories;
//   final String? selectedCategory; // Keep it nullable
//   final ValueChanged<String?>? onChanged; // Keep it nullable

//   const CategoriesChips({
//     super.key,
//     required this.categories,
//     required this.selectedCategory,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 8.0, // Adjust spacing between chips as needed
//       children: categories.map((category) {
//         return ChoiceChip(
//           selectedColor: AppColor.darkSurface.withOpacity(0.4),
//           backgroundColor: Colors.transparent,
//           label: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SvgPicture.asset(
//                 category.image,
//                 width: 16, // Adjust icon size as needed
//                 height: 16, // Adjust icon size as needed
//               ),
//               horizontalSpace(4),
//               Text(
//                 category.category,
//                 style: normalText(16, AppColor.secondary),
//               ),
//             ],
//           ),
//           selected: selectedCategory == category.category,
//           onSelected: (selected) {
//             // Check for null before calling onChanged
//             onChanged?.call(selected ? category.category : null);
//           },
//         );
//       }).toList(),
//     );
//   }
// }
