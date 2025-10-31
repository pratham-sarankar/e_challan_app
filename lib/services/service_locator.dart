import 'package:get_it/get_it.dart';
import '../services/api_services.dart';
import '../cubits/challan_types_cubit.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initialize all app dependencies
/// 
/// This should be called once during app initialization before
/// any widgets are created.
Future<void> setupServiceLocator() async {
  // Register ApiService as a singleton
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Register ChallanTypesCubit as a singleton
  // This ensures challan types are loaded once and shared globally
  getIt.registerLazySingleton<ChallanTypesCubit>(
    () => ChallanTypesCubit(getIt<ApiService>()),
  );
}
