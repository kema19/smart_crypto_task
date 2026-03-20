import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_crypto/bloc/crypto_event.dart';
import 'package:smart_crypto/bloc/crypto_state.dart';
import 'package:smart_crypto/crypto_model.dart';
import 'package:smart_crypto/crypto_repository.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoRepository cryptoRepository;

  List<CryptoModel> _originalList = [];
  List<CryptoModel> allCoins = [];
  
  CryptoBloc(this.cryptoRepository) : super(const CryptoState()) {
    on<FetchCryptoData>((event, emit) async {
      final localData = cryptoRepository.getLocalData();
      final favorites = cryptoRepository.getFavorites();
      if (localData.isNotEmpty) {
        emit(
          state.copyWith(
            cryptoList: localData,
            favoriteIds: favorites,
            isLoading: true,
            error: null,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: true, error: null));
      }

      await Future.delayed(Duration(seconds: 5));
      try {
        final data = await cryptoRepository.fetchCryptoData();
        _originalList = data;
       on<FilterFallEvent>((event, emit) {
  final filtered = allCoins
      .where((coin) => coin.changePercent < 0)
      .toList();

  emit(CryptoLoaded(filtered));
});

on<FilterTop10Event>((event, emit) {
  final sorted = List<CryptoModel>.from(allCoins)
    ..sort((a, b) => b.price.compareTo(a.price));

  emit(CryptoLoaded(sorted.take(10).toList()));
});
        
        emit(state.copyWith(isLoading: false, cryptoList: data));
      } catch (e) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Ошибка при получении данных',
          ),
        );
      }
    });

    on<FilterGainers>((event, emit) {
      final filtered = _originalList
          .where((item) => double.parse(item.changePercent24Hr) > 0)
          .toList();
      emit(state.copyWith(cryptoList: filtered));
    });

    on<ResetFilters>((event, emit) {
      emit(state.copyWith(cryptoList: _originalList));
    });

 on<ToggleFavorite>((event, emit) {
      final currentFavorites = Set<String>.from(state.favoriteIds);
      if (currentFavorites.contains(event.id)) {
        currentFavorites.remove(event.id);
      } else {
        currentFavorites.add(event.id);
      }
      cryptoRepository.toggleFavorite(event.id);
      emit(state.copyWith(favoriteIds: currentFavorites));
    });

    on<FilterFavorites>((event, emit) {
      emit(state.copyWith(showOnlyFavorites: !state.showOnlyFavorites));
    });

    on<ClearAllFavorites>((event, emit) {
      cryptoRepository.clearAllFavorites();
      emit(state.copyWith(favoriteIds: Set<String>.from({})));
    });
  }
}
