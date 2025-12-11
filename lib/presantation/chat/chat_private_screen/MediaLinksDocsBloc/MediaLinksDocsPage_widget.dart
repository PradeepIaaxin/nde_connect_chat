// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'MediaLinksDocsBloc.dart';
// import 'MediaLinksDocsEvent.dart';
// import 'MediaLinksDocsState.dart';

// class MediaLinksDocsPage extends StatelessWidget {
//   const MediaLinksDocsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => MediaLinksDocsBloc()..add(LoadMediaLinksDocs()),
//       child: DefaultTabController(
//         length: 3,
//         child: Scaffold(
//           appBar: AppBar(
//             title: Text("Media, Links, and Docs"),
//             bottom: TabBar(
//               tabs: [
//                 Tab(text: "Media"),
//                 Tab(text: "Links"),
//                 Tab(text: "Docs"),
//               ],
//             ),
//           ),
//           body: BlocBuilder<MediaLinksDocsBloc, MediaLinksDocsState>(
//             builder: (context, state) {
//               if (state is MediaLinksDocsLoading) {
//                 return Center(child: CircularProgressIndicator());
//               } else if (state is MediaLinksDocsLoaded) {
//                 return TabBarView(
//                   children: [
//                     MediaTab(mediaList: state.data.media),
//                     LinksTab(linkList: state.data.links),
//                     DocsTab(docList: state.data.docs),
//                   ],
//                 );
//               } else if (state is MediaLinksDocsError) {
//                 return Center(child: Text(state.error));
//               }
//               return Center(child: Text("Press reload to fetch data"));
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Media Tab
// class MediaTab extends StatelessWidget {
//   final List<String> mediaList;
//   const MediaTab({super.key, required this.mediaList});

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       padding: EdgeInsets.all(10),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: mediaList.length,
//       itemBuilder: (context, index) {
//         return Image.network(mediaList[index], fit: BoxFit.cover);
//       },
//     );
//   }
// }

// // Links Tab
// class LinksTab extends StatelessWidget {
//   final List<String> linkList;
//   const LinksTab({super.key, required this.linkList});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: EdgeInsets.all(10),
//       itemCount: linkList.length,
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: Icon(Icons.link, color: Colors.blue),
//           title: Text(linkList[index]),
//           onTap: () => log("Open link: ${linkList[index]}".toString()),
//         );
//       },
//     );
//   }
// }

// // Docs Tab
// class DocsTab extends StatelessWidget {
//   final List<String> docList;
//   const DocsTab({super.key, required this.docList});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: EdgeInsets.all(10),
//       itemCount: docList.length,
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: Icon(Icons.insert_drive_file, color: Colors.grey),
//           title: Text(docList[index]),
//           onTap: () => log("Open document: ${docList[index]}"),
//         );
//       },
//     );
//   }
// }
