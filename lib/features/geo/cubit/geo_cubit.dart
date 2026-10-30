import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/geo_place.dart';
import '../repositories/geo_repository.dart';
import 'geo_state.dart';

class GeoCubit extends Cubit<GeoState> {
  static const String keyActivePlaceId = 'active_geo_place_id';
  static const String keyIsMunicipalityWide = 'is_municipality_wide';

  final GeoRepository geoRepository;
  final SharedPreferences? _prefs;

  GeoCubit({
    required this.geoRepository,
    SharedPreferences? prefs,
    GeoState initialState = const GeoState(),
  })  : _prefs = prefs,
        super(initialState);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<void> loadPlaces({String? serverChecksum}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final places = await geoRepository.getGeoPlaces(serverChecksum: serverChecksum);
      final prefs = await _getPrefs();

      final savedPlaceId = prefs.getString(keyActivePlaceId);
      final savedMunicipalityWide = prefs.getBool(keyIsMunicipalityWide) ?? false;

      GeoPlace? resolvedPlace;
      if (savedPlaceId != null) {
        resolvedPlace = places.cast<GeoPlace?>().firstWhere(
              (p) => p?.id == savedPlaceId,
              orElse: () => null,
            );
      }

      // Ja nav saglabātas vietas vai tā vairs neeksistē, izvēlamies pirmo pieejamo
      resolvedPlace ??= places.isNotEmpty ? places.first : null;

      final bool isWide = (resolvedPlace != null && resolvedPlace.isStateCity)
          ? false
          : savedMunicipalityWide;

      emit(state.copyWith(
        places: places,
        activePlace: resolvedPlace,
        isMunicipalityWide: isWide,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Neizdevās ielādēt teritorijas: $e',
      ));
    }
  }

  Future<void> selectPlace(GeoPlace place) async {
    final prefs = await _getPrefs();
    await prefs.setString(keyActivePlaceId, place.id);

    // Ja izvēlēta valstspilsēta (piem., Rīga), novada režīms nav piemērojams
    final bool isWide = place.isStateCity ? false : state.isMunicipalityWide;
    if (place.isStateCity) {
      await prefs.setBool(keyIsMunicipalityWide, false);
    }

    emit(state.copyWith(
      activePlace: place,
      isMunicipalityWide: isWide,
    ));
  }

  Future<void> setMunicipalityWide(bool isWide) async {
    if (state.activePlace != null && state.activePlace!.isStateCity) {
      return;
    }

    final prefs = await _getPrefs();
    await prefs.setBool(keyIsMunicipalityWide, isWide);

    emit(state.copyWith(isMunicipalityWide: isWide));
  }

  Future<void> toggleMunicipalityWide() async {
    await setMunicipalityWide(!state.isMunicipalityWide);
  }
}

