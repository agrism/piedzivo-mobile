import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../geo/cubit/geo_cubit.dart';
import '../../geo/cubit/geo_state.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  static const List<String> _categories = [
    'Visi',
    'Koncerts',
    'Teātris',
    'Izstāde',
    'Kino',
    'Sports',
    'Ģimenei',
    'Zaļumballe',
  ];

  @override
  void initState() {
    super.initState();
    final geoState = context.read<GeoCubit>().state;
    context.read<EventsBloc>().add(LoadEvents(placeId: geoState.currentFilterPlaceId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeoCubit, GeoState>(
      listenWhen: (prev, curr) => prev.currentFilterPlaceId != curr.currentFilterPlaceId,
      listener: (context, geoState) {
        context.read<EventsBloc>().add(LoadEvents(placeId: geoState.currentFilterPlaceId));
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          children: [
            // 1. Ātro kategoriju čipu josla
            _buildCategoryBar(context),

            // 2. Pasākumu saraksts ar dienu grupējumu
            Expanded(
              child: BlocBuilder<EventsBloc, EventsState>(
                builder: (context, state) {
                  if (state is EventsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryViolet),
                    );
                  }

                  if (state is EventsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final placeId = context.read<GeoCubit>().state.currentFilterPlaceId;
                                context.read<EventsBloc>().add(LoadEvents(placeId: placeId, forceRefresh: true));
                              },
                              child: const Text('Mēģināt vēlreiz'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is EventsLoaded) {
                    if (state.filteredEvents.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          final placeId = context.read<GeoCubit>().state.currentFilterPlaceId;
                          context.read<EventsBloc>().add(LoadEvents(placeId: placeId, forceRefresh: true));
                        },
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text(
                                    'Šajos filtros pasākumi netika atrasti',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = state.groupedEvents;
                    final dayHeaders = grouped.keys.toList();

                    return RefreshIndicator(
                      color: AppColors.primaryViolet,
                      onRefresh: () async {
                        final placeId = context.read<GeoCubit>().state.currentFilterPlaceId;
                        context.read<EventsBloc>().add(LoadEvents(placeId: placeId, forceRefresh: true));
                      },
                      child: ListView.builder(
                        itemCount: dayHeaders.length,
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemBuilder: (context, index) {
                          final header = dayHeaders[index];
                          final dayEvents = grouped[header] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dienas virsraksts (ŠODIEN, RĪT, DATUMS)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  header,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),

                              // Šīs dienas pasākumu kartītes
                              ...dayEvents.map((event) => EventCard(key: ValueKey(event.id), event: event)),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        final selectedCat = state is EventsLoaded ? state.selectedCategory : null;
        final isFreeOnly = state is EventsLoaded ? state.isFreeOnly : false;

        return Container(
          height: 48,
          margin: const EdgeInsets.only(top: 6, bottom: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Bezmaksas slēdža čips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  key: const Key('filter_chip_free'),
                  label: const Text('🎟️ Bezmaksas'),
                  selected: isFreeOnly,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFDCFCE7),
                  backgroundColor: AppColors.cardWhite,
                  side: BorderSide(
                    color: isFreeOnly ? const Color(0xFF86EFAC) : AppColors.borderSubtle,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFreeOnly ? const Color(0xFF15803D) : AppColors.primaryNavy,
                  ),
                  onSelected: (val) {
                    context.read<EventsBloc>().add(FilterEvents(
                          category: selectedCat,
                          isFreeOnly: val,
                        ));
                  },
                ),
              ),

              // Standarta kategoriju čipi
              ..._categories.map((cat) {
                final isSelected = cat == 'Visi' ? selectedCat == null : selectedCat == cat;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    key: Key('category_chip_$cat'),
                    label: Text(cat),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryViolet,
                    backgroundColor: AppColors.cardWhite,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryViolet : AppColors.borderSubtle,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                    ),
                    onSelected: (selected) {
                      final targetCategory = cat == 'Visi' ? null : (selected ? cat : null);
                      context.read<EventsBloc>().add(FilterEvents(
                            category: targetCategory,
                            isFreeOnly: isFreeOnly,
                          ));
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
