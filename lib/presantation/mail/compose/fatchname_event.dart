import 'package:equatable/equatable.dart';

abstract class FatchnameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Fetch sender email
class FetchSenderEmailEvent extends FatchnameEvent {}
