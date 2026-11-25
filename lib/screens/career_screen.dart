import 'package:flutter/material.dart';
import '../services/ui_strings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veridian/services/career_service.dart';
import 'package:veridian/models/job_opportunity.dart';
import 'package:veridian/providers/localization_provider.dart'; // Добавлен

class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
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
      context.read<CareerService>().searchJobs(query);
    }
  }

  Future<void> _applyJob(
      String? urlString, LocalizationProvider localization) async {
    if (urlString == null) return;
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
    final careerService = context.watch<CareerService>();
    final localization = context.watch<LocalizationProvider>(); // Провайдер
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localization.translate('career'),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: localization.translate('search_hint_job'), // Ключ
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFFF5F5F5),
                    prefixIcon: const Icon(Icons.work_outline),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: theme.primaryColor),
                      onPressed: _performSearch,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: careerService.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor))
                : careerService.error != null
                    ? Center(
                        child: Text(uiText('Не удалось загрузить вакансии.'),
                            style: const TextStyle(color: Colors.red)))
                    : careerService.jobs.isEmpty
                        ? _buildEmptyState(
                            careerService.hasSearched, localization)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: careerService.jobs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _JobCard(
                                job: careerService.jobs[index],
                                onApply: () => _applyJob(
                                    careerService.jobs[index].jobApplyLink,
                                    localization),
                                localization:
                                    localization, // Передаем локализацию
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasSearched, LocalizationProvider localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasSearched ? Icons.search_off : Icons.work_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            hasSearched
                ? localization.translate('no_results_found') // Ключ
                : localization.translate('enter_job_title'), // Ключ
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobOpportunity job;
  final VoidCallback onApply;
  final LocalizationProvider localization;

  const _JobCard(
      {required this.job, required this.onApply, required this.localization});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onApply,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle == 'Без названия'
                                ? uiText(job.jobTitle)
                                : job.jobTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.employerName,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${job.jobCity ?? localization.translate('city_not_specified')}, ${job.jobCountry ?? 'KZ'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    if (job.jobEmploymentType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.jobEmploymentType!,
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                if (job.jobDescription != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    job.jobDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
