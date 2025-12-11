import 'package:flutter/material.dart';

class StorageItem {
  final int size;
  final int order;
  final String type;

  StorageItem({required this.size, required this.order, required this.type});

  double get sizeInGB => size / (1024 * 1024 * 1024);
  double get sizeInMB => size / (1024 * 1024);
}

abstract class StorageState {}

class StorageInitial extends StorageState {}

class StorageLoading extends StorageState {}

class StorageLoaded extends StorageState {
  final List<StorageItem> items;
  final int totalSize;

  StorageLoaded({required this.items, required this.totalSize});

  double get usagePercent =>
      totalSize / (15 * 1024 * 1024 * 1024); // Assuming 15GB quota
}

class StorageError extends StorageState {
  final String message;
  StorageError(this.message);
}
