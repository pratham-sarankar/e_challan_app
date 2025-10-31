import 'package:equatable/equatable.dart';
import '../models/challan_type.dart';

/// State class for challan types
abstract class ChallanTypesState extends Equatable {
  const ChallanTypesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading
class ChallanTypesInitial extends ChallanTypesState {
  const ChallanTypesInitial();
}

/// Loading state
class ChallanTypesLoading extends ChallanTypesState {
  const ChallanTypesLoading();
}

/// Successfully loaded state with data
class ChallanTypesLoaded extends ChallanTypesState {
  final List<ChallanType> challanTypes;

  const ChallanTypesLoaded(this.challanTypes);

  @override
  List<Object?> get props => [challanTypes];
}

/// Error state
class ChallanTypesError extends ChallanTypesState {
  final String message;

  const ChallanTypesError(this.message);

  @override
  List<Object?> get props => [message];
}
