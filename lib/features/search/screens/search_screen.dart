import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/widgets/event_card.dart';
import '../../geo/cubit/geo_cubit.dart';
import '../../geo/cubit/geo_state.dart';
import '../../places/widgets/place_card.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

  static const List<String> _suggestedQueries = [
    'Koncerti',
    'Izstādes',
    'Teātris',
    'Restorāni',
    'Bērniem',
    'Festivāli',
    'Muzeji',
    'Daba',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<SearchBloc>().state.query;
    _textController = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {}); // For clear button visibility
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final geoState = context.read<GeoCubit>().state;
      final searchState = context.read<SearchBloc>().state;
      context.read<SearchBloc>().add(
            SearchQueryChanged(
              query,
              placeId: geoState.activePlace?.id,
              isLatviaWide: searchState.isLatviaWide,
            ),
          );
    });
  }

  void _submitQuery(String query) {
    _debounceTimer?.cancel();
    final geoState = context.read<GeoCubit>().state;
    final searchState = context.read<SearchBloc>().state;
    context.read<SearchBloc>().add(
          SearchQueryChanged(
            query,
            placeId: geoState.activePlace?.id,
            isLatviaWide: searchState.isLatviaWide,
          ),
        );
  }

  void _clearSearch() {
    _textController.clear();
    _debounceTimer?.cancel();
    context.read<SearchBloc>().add(const SearchClear());
    setState(() {});
  }

  void _selectSuggestion(String suggestion) {
    _textController.text = suggestion;
    if (!AppTheme.isTestMode) {
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    }
    _submitQuery(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeoCubit, GeoState>(
      builder: (context, geoState) {
        return BlocBuilder<SearchBloc, SearchState>(
          builder: (context, searchState) {
            final activeCityName = geoState.activePlace?.name ?? 'Mana pilsēta';

            return Scaffold(
              backgroundColor: AppColors.backgroundLight,
              appBar: _buildSearchBar(context, searchState, activeCityName),
              body: Column(
                children: [
                  _buildScopeToggle(context, searchState, geoState),
                  if (searchState.status == SearchStatus.success &&
                      searchState.totalCount > 0)
                    _buildTabs(context, searchState),
                  Expanded(
                    child: _buildBody(
                      context,
                      searchState,
                      activeCityName,
                      geoState,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildSearchBar(
    BuildContext context,
    SearchState searchState,
    String activeCityName,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68.0),
      child: Container(
        color: AppColors.cardWhite,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Atpakaļ poga
                IconButton(
                  key: const Key('search_back_button'),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                const SizedBox(width: 4),

                // Teksta meklēšanas lauks
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                      border: Border.all(color: AppColors.borderSubtle, width: 1),
                    ),
                    child: TextField(
                      key: const Key('search_input_field'),
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      autofocus: !AppTheme.isTestMode,
                      showCursor: !AppTheme.isTestMode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryNavy,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Meklēt pasākumus un vietas...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        suffixIcon: _textController.text.isNotEmpty
                            ? IconButton(
                                key: const Key('search_clear_button'),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: _onQueryChanged,
                      onSubmitted: _submitQuery,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScopeToggle(
    BuildContext context,
    SearchState searchState,
    GeoState geoState,
  ) {
    final activeCityName = geoState.activePlace?.name ?? 'Pilsētā';

    return Container(
      color: AppColors.cardWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Pilsēta scope
          Expanded(
            child: GestureDetector(
              key: const Key('search_scope_city'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (searchState.isLatviaWide) {
                  context.read<SearchBloc>().add(
                        SearchScopeChanged(
                          isLatviaWide: false,
                          placeId: geoState.activePlace?.id,
                        ),
                      );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !searchState.isLatviaWide
                      ? AppColors.primaryViolet
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  border: Border.all(
                    color: !searchState.isLatviaWide
                        ? AppColors.primaryViolet
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: !searchState.isLatviaWide
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activeCityName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: !searchState.isLatviaWide
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Visa Latvija scope
          Expanded(
            child: GestureDetector(
              key: const Key('search_scope_all'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!searchState.isLatviaWide) {
                  context.read<SearchBloc>().add(
                        SearchScopeChanged(
                          isLatviaWide: true,
                          placeId: geoState.activePlace?.id,
                        ),
                      );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: searchState.isLatviaWide
                      ? AppColors.primaryViolet
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  border: Border.all(
                    color: searchState.isLatviaWide
                        ? AppColors.primaryViolet
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇱🇻', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      'Visā Latvijā',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: searchState.isLatviaWide
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, SearchState searchState) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildTabItem(
            context,
            key: const Key('search_tab_all'),
            label: 'Visi (${searchState.totalCount})',
            isSelected: searchState.selectedTab == SearchTab.all,
            onTap: () => context.read<SearchBloc>().add(const SearchTabChanged(SearchTab.all)),
          ),
          const SizedBox(width: 8),
          _buildTabItem(
            context,
            key: const Key('search_tab_events'),
            label: 'Pasākumi (${searchState.events.length})',
            isSelected: searchState.selectedTab == SearchTab.events,
            onTap: () => context.read<SearchBloc>().add(const SearchTabChanged(SearchTab.events)),
          ),
          const SizedBox(width: 8),
          _buildTabItem(
            context,
            key: const Key('search_tab_places'),
            label: 'Vietas (${searchState.places.length})',
            isSelected: searchState.selectedTab == SearchTab.places,
            onTap: () => context.read<SearchBloc>().add(const SearchTabChanged(SearchTab.places)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryViolet.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            border: Border.all(
              color: isSelected ? AppColors.primaryViolet : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primaryViolet : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchState searchState,
    String activeCityName,
    GeoState geoState,
  ) {
    if (searchState.status == SearchStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('search_loading_indicator'),
          color: AppColors.primaryViolet,
        ),
      );
    }

    if (searchState.status == SearchStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                searchState.errorMessage ?? 'Radās kļūda meklēšanas laikā',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitQuery(_textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
                child: const Text('Mēģināt vēlreiz'),
              ),
            ],
          ),
        ),
      );
    }

    // 0 rezultātu stāvoklis
    if (searchState.isEmpty) {
      if (!searchState.isLatviaWide) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nav atrasts $activeCityName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mēģini meklēt visā Latvijā vai pārbaudi vaicājumu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('search_nationwide_button'),
                  onPressed: () {
                    context.read<SearchBloc>().add(
                          SearchScopeChanged(
                            isLatviaWide: true,
                            placeId: geoState.activePlace?.id,
                          ),
                        );
                  },
                  icon: const Text('🇱🇻', style: TextStyle(fontSize: 16)),
                  label: const Text(
                    'Meklēt visā Latvijā',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nekas netika atrasts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pēc vaicājuma "${searchState.query}" netika atrasts neviens pasākums vai vieta visā Latvijā.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Sākotnējais tukšais stāvoklis ar ieteikumu birkām
    if (searchState.status == SearchStatus.initial || _textController.text.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Ieteiktie meklējumi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQueries.map((query) {
              return ActionChip(
                key: Key('search_chip_$query'),
                label: Text(query),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
                backgroundColor: AppColors.cardWhite,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                ),
                onPressed: () => _selectSuggestion(query),
              );
            }).toList(),
          ),
        ],
      );
    }

    // Rezultātu saraksts
    return _buildResultsList(context, searchState);
  }

  Widget _buildResultsList(BuildContext context, SearchState searchState) {
    final showEvents = searchState.selectedTab == SearchTab.all ||
        searchState.selectedTab == SearchTab.events;
    final showPlaces = searchState.selectedTab == SearchTab.all ||
        searchState.selectedTab == SearchTab.places;

    final events = searchState.events;
    final places = searchState.places;

    return ListView(
      key: ValueKey('search_results_${searchState.selectedTab}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (showEvents && events.isNotEmpty) ...[
          if (searchState.selectedTab == SearchTab.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Pasākumi (${events.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ...events.map(
            (event) => EventCard(
              key: Key('search_event_${event.id}'),
              event: event,
            ),
          ),
        ],
        if (showPlaces && places.isNotEmpty) ...[
          if (searchState.selectedTab == SearchTab.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                'Vietas (${places.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ...places.map(
            (place) => PlaceCard(
              key: Key('search_place_${place.id}'),
              place: place,
            ),
          ),
        ],
        if (searchState.selectedTab == SearchTab.events && events.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Šajā kategorijā pasākumi netika atrasti',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        if (searchState.selectedTab == SearchTab.places && places.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Šajā kategorijā vietas netika atrastas',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
