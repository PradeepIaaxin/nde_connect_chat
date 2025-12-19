import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/storage/storage_bloc.dart';
import 'package:nde_email/presantation/drive/Bloc/storage/storage_event.dart';
import 'package:nde_email/presantation/drive/Bloc/storage/storage_state.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  Color getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'images':
        return Colors.orangeAccent;
      case 'videos':
        return Colors.teal;
      case 'documents':
        return Colors.blueAccent;
      case 'audios':
        return Colors.purpleAccent;
      case 'others':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxSize = 5 * 1024 * 1024 * 1024;

    return BlocProvider(
      create: (_) => StorageBloc()..add(FetchStorageData()),
      child: Scaffold(
        backgroundColor: Colors.white,
        
        appBar: AppBar(
          title: const Text('Storage', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<StorageBloc, StorageState>(
            builder: (context, state) {
              if (state is StorageLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is StorageLoaded) {
                final usedMB = state.totalSize / (1024 * 1024);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Used Storage",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${usedMB.toStringAsFixed(2)} MB of 5 GB",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Storage usage bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          ...state.items.map((item) {
                            return Expanded(
                              flex: item.size > 0 ? item.size : 1, // real size
                              child: Container(
                                height: 14,
                                color: getColorByType(item.type),
                              ),
                            );
                          }).toList(),
                          if (state.totalSize < maxSize)
                            Expanded(
                              flex: (maxSize - state.totalSize) > 0
                                  ? (maxSize - state.totalSize)
                                  : 1,
                              child: Container(
                                height: 14,
                                color: Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Storage breakdown list
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final color = getColorByType(item.type);
                          final sizeMB = item.size / (1024 * 1024);
                          final sizeGB = sizeMB / 1024;
                          final sizeDisplay = sizeMB > 1024
                              ? "${sizeGB.toStringAsFixed(2)} GB"
                              : "${sizeMB.toStringAsFixed(2)} MB";

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 6,
                                  color: Colors.black.withOpacity(0.05),
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 8, backgroundColor: color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(item.type,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Text(sizeDisplay,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else if (state is StorageError) {
                return Center(
                    child: Text(state.message,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16)));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
