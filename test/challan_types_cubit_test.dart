import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:municipal_e_challan/cubits/challan_types_cubit.dart';
import 'package:municipal_e_challan/cubits/challan_types_state.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:municipal_e_challan/models/challan_type.dart';

// Generate mocks with mockito
@GenerateMocks([ApiService])
import 'challan_types_cubit_test.mocks.dart';

void main() {
  group('ChallanTypesCubit', () {
    late MockApiService mockApiService;
    late ChallanTypesCubit cubit;

    setUp(() {
      mockApiService = MockApiService();
      cubit = ChallanTypesCubit(mockApiService);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ChallanTypesInitial', () {
      expect(cubit.state, equals(const ChallanTypesInitial()));
    });

    blocTest<ChallanTypesCubit, ChallanTypesState>(
      'emits [ChallanTypesLoading, ChallanTypesLoaded] when loadChallanTypes succeeds',
      build: () {
        final testTypes = [
          ChallanType(
            id: 1,
            typeName: 'Test Violation',
            fineAmount: 500,
            description: 'Test description',
            isActive: 'active',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ];
        when(mockApiService.getChallanTypes())
            .thenAnswer((_) async => testTypes);
        return cubit;
      },
      act: (cubit) => cubit.loadChallanTypes(),
      expect: () => [
        const ChallanTypesLoading(),
        isA<ChallanTypesLoaded>()
            .having((state) => state.challanTypes.length, 'length', 1)
            .having((state) => state.challanTypes[0].typeName, 'typeName', 'Test Violation'),
      ],
    );

    blocTest<ChallanTypesCubit, ChallanTypesState>(
      'emits [ChallanTypesLoading, ChallanTypesError] when loadChallanTypes fails',
      build: () {
        when(mockApiService.getChallanTypes())
            .thenThrow(Exception('Network error'));
        when(mockApiService.lastGetChallanTypesStatus).thenReturn(500);
        return cubit;
      },
      act: (cubit) => cubit.loadChallanTypes(),
      expect: () => [
        const ChallanTypesLoading(),
        isA<ChallanTypesError>()
            .having((state) => state.message, 'message', contains('Network error')),
      ],
    );

    blocTest<ChallanTypesCubit, ChallanTypesState>(
      'does not emit new states when already loading',
      build: () {
        final testTypes = [
          ChallanType(
            id: 1,
            typeName: 'Test Violation',
            fineAmount: 500,
            description: 'Test description',
            isActive: 'active',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ];
        when(mockApiService.getChallanTypes())
            .thenAnswer((_) async {
          // Simulate slow response
          await Future.delayed(const Duration(milliseconds: 100));
          return testTypes;
        });
        return cubit;
      },
      act: (cubit) async {
        // Start first load
        cubit.loadChallanTypes();
        // Try to start second load immediately (should be ignored)
        await cubit.loadChallanTypes();
      },
      expect: () => [
        const ChallanTypesLoading(),
        isA<ChallanTypesLoaded>(),
      ],
    );

    blocTest<ChallanTypesCubit, ChallanTypesState>(
      'retry calls loadChallanTypes again',
      build: () {
        final testTypes = [
          ChallanType(
            id: 1,
            typeName: 'Test Violation',
            fineAmount: 500,
            description: 'Test description',
            isActive: 'active',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ];
        when(mockApiService.getChallanTypes())
            .thenAnswer((_) async => testTypes);
        return cubit;
      },
      act: (cubit) => cubit.retry(),
      expect: () => [
        const ChallanTypesLoading(),
        isA<ChallanTypesLoaded>(),
      ],
    );
  });
}
