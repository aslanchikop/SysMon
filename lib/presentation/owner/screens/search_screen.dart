// 🐾 Search Screen with Filters for Pet Owners in Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';
import 'provider_details_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'vet_clinic', 'grooming'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tabs.search')),
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Искать ветеринара, грумера...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Фильтры типа бизнеса
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterButton('all', 'Все', theme),
                const SizedBox(width: 8),
                _buildFilterButton('vet_clinic', 'Ветклиники', theme),
                const SizedBox(width: 8),
                _buildFilterButton('grooming', 'Груминг', theme),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Результаты поиска
          Expanded(
            child: providersAsync.when(
              data: (providers) {
                final filtered = providers.where((provider) {
                  final matchesType = _typeFilter == 'all' || provider['type'] == _typeFilter;
                  final matchesName = provider['business_name'].toString().toLowerCase().contains(_searchQuery) ||
                      (provider['description']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                      provider['address'].toString().toLowerCase().contains(_searchQuery);
                  return matchesType && matchesName;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Ничего не найдено',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Попробуйте изменить поисковый запрос или фильтры',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final provider = filtered[index];
                    final isClinic = provider['type'] == 'vet_clinic';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isClinic ? Icons.local_hospital_rounded : Icons.content_cut_rounded,
                            color: isClinic ? theme.colorScheme.primary : theme.colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          provider['business_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(provider['address'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${provider['rating']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailsScreen(provider: provider),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Ошибка: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String type, String label, ThemeData theme) {
    final isSelected = _typeFilter == type;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _typeFilter = type;
          });
        }
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
