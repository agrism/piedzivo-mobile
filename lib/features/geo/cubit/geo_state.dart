import 'package:equatable/equatable.dart';
import '../models/geo_place.dart';

class GeoState extends Equatable {
  final List<GeoPlace> places;
  final GeoPlace? activePlace;
  final bool isMunicipalityWide;
  final bool isLoading;
  final String? errorMessage;

  const GeoState({
    this.places = const [],
    this.activePlace,
    this.isMunicipalityWide = false,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasActivePlace => activePlace != null;

  String get activePlaceName => activePlace?.name ?? 'Visa Latvija';

  String? get municipalityName =>
      activePlace?.parent?.name ??
      (activePlace?.type == 'municipality' ? activePlace?.name : null);

  /// Slēdzis "Visā novadā" ir aktīvs tikai tad, ja pilsētai ir piesaistīts novads (nav valstspilsēta)
  bool get canToggleMunicipality =>
      activePlace != null && !activePlace!.isStateCity && activePlace!.parent != null;

  /// ID, pēc kura filtrēt pasākumus un vietas (pilsētas ID vai novada ID, ja ieslēgts isMunicipalityWide)
  String? get currentFilterPlaceId {
    if (isMunicipalityWide && activePlace?.parent != null) {
      return activePlace!.parent!.id;
    }
    return activePlace?.id;
  }

  GeoState copyWith({
    List<GeoPlace>? places,
    GeoPlace? activePlace,
    bool? isMunicipalityWide,
    bool? isLoading,
    String? errorMessage,
    bool clearActivePlace = false,
    bool clearError = false,
  }) {
    return GeoState(
      places: places ?? this.places,
      activePlace: clearActivePlace ? null : (activePlace ?? this.activePlace),
      isMunicipalityWide: isMunicipalityWide ?? this.isMunicipalityWide,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        places,
        activePlace,
        isMunicipalityWide,
        isLoading,
        errorMessage,
      ];
}

