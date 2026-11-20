class JobOpportunity {
  final String jobId;
  final String jobTitle;
  final String employerName;
  final String? jobCity;
  final String? jobCountry;
  final String? jobApplyLink;
  final String? jobEmploymentType;
  final String? jobDescription;

  JobOpportunity({
    required this.jobId,
    required this.jobTitle,
    required this.employerName,
    this.jobCity,
    this.jobCountry,
    this.jobApplyLink,
    this.jobEmploymentType,
    this.jobDescription,
  });

  factory JobOpportunity.fromJson(Map<String, dynamic> json) {
    return JobOpportunity(
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['job_title'] ?? 'Без названия',
      employerName: json['employer_name'] ?? 'Не указан',
      jobCity: json['job_city'],
      jobCountry: json['job_country'],
      jobApplyLink: json['job_apply_link'],
      jobEmploymentType: json['job_employment_type'],
      jobDescription: json['job_description'],
    );
  }
}