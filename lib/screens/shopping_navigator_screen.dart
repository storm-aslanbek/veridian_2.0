import 'package:flutter/material.dart';
import 'package:veridian/services/ui_strings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veridian/services/shopping_service.dart';
import 'package:veridian/models/search_result.dart';
import 'package:veridian/providers/localization_provider.dart'; // Добавлен импорт

class ShoppingNavigatorScreen extends StatefulWidget {
  const ShoppingNavigatorScreen({super.key});

  @override
  State<ShoppingNavigatorScreen> createState() =>
      _ShoppingNavigatorScreenState();
}

class _ShoppingNavigatorScreenState extends State<ShoppingNavigatorScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      FocusScope.of(context).unfocus();
      context.read<ShoppingService>().searchProducts(query);
    }
  }

  Future<void> _openLink(
      String urlString, LocalizationProvider localization) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.translate('error_open_link'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingService = context.watch<ShoppingService>();
    final localization = context.watch<LocalizationProvider>(); // Провайдер
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localization.translate('shopping_navigator'),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // === БЛОК ПОИСКА ===
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('search_suppliers'), // Ключ
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  localization.translate('search_suppliers_desc'), // Ключ
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText:
                        localization.translate('search_hint_product'), // Ключ
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFFF5F5F5),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.arrow_forward, color: primaryColor),
                      onPressed: _performSearch,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          // === РЕЗУЛЬТАТЫ ===
          Expanded(
            child: shoppingService.isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : shoppingService.error != null
                    ? Center(
                        child: Text(uiText(shoppingService.error!),
                            style: const TextStyle(color: Colors.grey)))
                    : shoppingService.results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                    localization.translate(
                                        'search_results_placeholder'),
                                    style: const TextStyle(
                                        color: Colors.grey)), // Ключ
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: shoppingService.results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _ResultCard(
                                item: shoppingService.results[index],
                                onTap: () => _openLink(
                                    shoppingService.results[index].link,
                                    localization),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ... (класс _ResultCard без изменений в переводах, только тема) ...
class _ResultCard extends StatelessWidget {
  final SearchResult item;
  final VoidCallback onTap;

  const _ResultCard({required this.item, required this.onTap});

  String _truncate(String text, int limit) {
    if (text.length <= limit) return text;
    return "${text.substring(0, limit)}...";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.open_in_new,
                        size: 18, color: theme.primaryColor),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.snippet != null && item.snippet!.isNotEmpty) ...[
                  Text(
                    _truncate(item.snippet!, 120),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _truncate(item.link, 40),
                    style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
