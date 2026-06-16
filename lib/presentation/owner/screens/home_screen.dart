// 🐾 Home Map Screen for Pet Owners in Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';
import 'provider_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'all'; // 'all', 'vet_clinic', 'grooming', 'walking'

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. ИНТЕРАКТИВНАЯ КАРТА (Демо-заглушка премиум-класса)
          _buildInteractiveMockMap(theme, providersAsync),

          // 2. ВЕРХНЯЯ ПАНЕЛЬ С ПОИСКОМ И КАТЕГОРИЯМИ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Поисковая строка
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Поиск клиник и услуг в Астане...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.tune_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Скролл категорий
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('all', '🐾 Все', theme),
                        _buildCategoryChip('vet_clinic', '🏥 Ветклиники', theme),
                        _buildCategoryChip('grooming', '✂️ Груминг', theme),
                        _buildCategoryChip('walking', '🐕 Выгул', theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. НИЖНИЙ СПИСОК КЛИНИК (Слайдер карточек)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            height: 180,
            child: providersAsync.when(
              data: (providers) {
                // Фильтруем провайдеров по выбранной категории
                final filtered = _selectedCategory == 'all'
                    ? providers
                    : providers.where((p) => p['type'] == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Нет заведений в этой категории',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                return PageView.builder(
                  controller: PageController(viewportFraction: 0.88),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final provider = filtered[index];
                    return _buildProviderCard(context, provider, theme);
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

  Widget _buildCategoryChip(String value, String label, ThemeData theme) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF252642),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
    );
  }

  // Честный красивый симулятор карты Астаны
  Widget _buildInteractiveMockMap(ThemeData theme, AsyncValue<List<Map<String, dynamic>>> providersAsync) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF131424) : const Color(0xFFECEFF1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Стилизованные схематичные дороги и реки (Астана, Ишим)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(isDark: isDark),
                ),
              ),
              
              // Метки (Пины) клиник
              ...providersAsync.maybeWhen(
                data: (providers) {
                  return providers.map((provider) {
                    // Используем координаты lat/lng для распределения по карте
                    final double lat = provider['lat'] ?? 51.16;
                    final double lng = provider['lng'] ?? 71.43;
                    
                    // Масштабируем координаты под экран
                    final x = constraints.maxWidth * (0.3 + (lng - 71.41) * 3);
                    final y = constraints.maxHeight * (0.4 - (lat - 51.15) * 5);
                    
                    final isSelected = _selectedCategory == 'all' || provider['type'] == _selectedCategory;
                    if (!isSelected) return const SizedBox.shrink();

                    return Positioned(
                      left: x.clamp(20.0, constraints.maxWidth - 60.0),
                      top: y.clamp(120.0, constraints.maxHeight - 240.0),
                      child: GestureDetector(
                        onTap: () {
                          // Показываем детали клиники
                          _openProviderDetails(context, provider);
                        },
                        child: _buildMapPin(provider, theme),
                      ),
                    );
                  }).toList();
                },
                orElse: () => [],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapPin(Map<String, dynamic> provider, ThemeData theme) {
    final isClinic = provider['type'] == 'vet_clinic';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(
            provider['business_name'].split(' «').first,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Icon(
          Icons.location_on_rounded,
          size: 38,
          color: isClinic ? theme.colorScheme.primary : theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildProviderCard(BuildContext context, Map<String, dynamic> provider, ThemeData theme) {
    final isClinic = provider['type'] == 'vet_clinic';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () => _openProviderDetails(context, provider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Иконка категории / Превью картинка
                Container(
                  width: 90,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isClinic ? Icons.local_hospital_rounded : Icons.content_cut_rounded,
                    size: 44,
                    color: isClinic ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Детали заведения
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        provider['business_name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider['address'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${provider['rating']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${provider['review_count']} отзывов)',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openProviderDetails(BuildContext context, Map<String, dynamic> provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderDetailsScreen(provider: provider),
      ),
    );
  }
}

// Рисовальщик дорог и реки для демо-карты Астаны
class _MapPainter extends CustomPainter {
  final bool isDark;

  _MapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF20223A) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final riverPaint = Paint()
      ..color = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFB3E5FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0;

    // Река Ишим
    final riverPath = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.45,
        size.width * 0.5,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.75,
        size.width,
        size.height * 0.7,
      );

    canvas.drawPath(riverPath, riverPaint);

    // Дороги (Кабанбай батыра, Туран, Мангилик Ел)
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.75, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
