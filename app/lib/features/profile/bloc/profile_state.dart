import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ClientProfileLoaded extends ProfileState {
  final ClientModel client;
  const ClientProfileLoaded(this.client);
  @override
  List<Object?> get props => [client];
}

class ContractorProfileLoaded extends ProfileState {
  final ContractorModel contractor;
  const ContractorProfileLoaded(this.contractor);
  @override
  List<Object?> get props => [contractor];
}

class ProfileSaved extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
