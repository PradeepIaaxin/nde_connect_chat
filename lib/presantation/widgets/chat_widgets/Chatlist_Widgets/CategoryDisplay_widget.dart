// // Widget for displaying the selected category
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
//
// class CategoryDisplay extends StatelessWidget {
//   const CategoryDisplay({super.key});
//
//   final List<String> categories = const ["All", "Unread", "Groups"];
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ChatHomeCubit, int>(
//       builder: (context, selectedIndex) {
//         return Center(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(24),
//               color: Colors.grey[200],
//             ),
//             child: Text(
//               "Showing: ${categories[selectedIndex]}",
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
//
//
//
//
