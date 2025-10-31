import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_services.dart';
import 'challan_types_state.dart';

/// Global cubit for managing challan types
/// 
/// This cubit loads challan types once at app startup and makes them
/// available throughout the app, reducing duplicate API calls and
/// improving performance.
class ChallanTypesCubit extends Cubit<ChallanTypesState> {
  final ApiService _apiService;

  ChallanTypesCubit(this._apiService) : super(const ChallanTypesInitial());

  /// Load challan types from the API
  /// 
  /// This method should be called once during app initialization.
  /// It includes retry logic for handling transient errors.
  Future<void> loadChallanTypes({int attempt = 0}) async {
    if (state is ChallanTypesLoading) {
      // Prevent concurrent loads
      return;
    }

    emit(const ChallanTypesLoading());

    try {
      final types = await _apiService.getChallanTypes();
      print('[ChallanTypesCubit] Loaded ${types.length} challan types');
      emit(ChallanTypesLoaded(types));
    } catch (e) {
      print('[ChallanTypesCubit] Error loading challan types: $e');
      
      // Retry logic for transient errors (e.g., 401 auth issues during startup)
      // Use the getter method for consistency
      final status = _apiService.getLastChallanTypesStatus();
      if ((status == 401 || status == 0) && attempt < 3) {
        final nextAttempt = attempt + 1;
        print('[ChallanTypesCubit] Retrying (attempt $nextAttempt)...');
        await Future.delayed(const Duration(milliseconds: 800));
        return loadChallanTypes(attempt: nextAttempt);
      }

      emit(ChallanTypesError(e.toString()));
    }
  }

  /// Retry loading challan types
  /// 
  /// This can be called from the UI when an error occurs to allow
  /// the user to manually retry.
  Future<void> retry() async {
    return loadChallanTypes();
  }
}
