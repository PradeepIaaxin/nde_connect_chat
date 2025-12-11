// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../../bloc/maile/bloc.dart';
//
// class CategorySelector extends StatelessWidget {
//   const CategorySelector({super.key});
//
//   final List<String> categories = const ["All", "Unread", "Groups"];
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: SizedBox(
//         height: 40,
//         child: BlocBuilder<ChatHomeCubit, int>(
//           builder: (context, selectedIndex) {
//             return ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: categories.length,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () => context.read<ChatHomeCubit>().selectCategory(index),
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 6),
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: selectedIndex == index ? Colors.blue : Colors.grey[300],
//                       borderRadius: const BorderRadius.all(Radius.circular(24)),
//                     ),
//                     child: Center(
//                       child: Text(
//                         categories[index],
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           decoration: TextDecoration.underline,
//                           decorationThickness: 0.5,
//                           decorationColor: Colors.black,
//                           color: selectedIndex == index ? Colors.white : Colors.black,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
