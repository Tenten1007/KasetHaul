import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();
  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterClientSuccess extends RegisterState {
  final ClientModel client;
  const RegisterClientSuccess({required this.client});
  @override
  List<Object?> get props => [client];
}

class RegisterContractorSuccess extends RegisterState {
  final ContractorModel contractor;
  const RegisterContractorSuccess({required this.contractor});
  @override
  List<Object?> get props => [contractor];
}

class RegisterError extends RegisterState {
  final String message;
  const RegisterError({required this.message});
  @override
  List<Object?> get props => [message];
}
