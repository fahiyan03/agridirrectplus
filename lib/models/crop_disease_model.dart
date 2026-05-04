class CropDiseaseModel {
  final bool isHealthy;
  final String? message;
  final List<DiseaseDetail> diseases;

  CropDiseaseModel({
    required this.isHealthy,
    this.message,
    required this.diseases,
  });

  factory CropDiseaseModel.fromMap(Map<String, dynamic> map) {
    final diseaseList = (map['diseases'] as List?) ?? [];
    return CropDiseaseModel(
      isHealthy: map['is_healthy'] ?? true,
      message:   map['message'],
      diseases:  diseaseList
          .map((d) => DiseaseDetail.fromMap(d as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasDiseases => diseases.isNotEmpty;
}

class DiseaseDetail {
  final String name;
  final String probability;
  final String commonNames;
  final String treatmentBiological;
  final String treatmentChemical;
  final String treatmentPrevention;

  DiseaseDetail({
    required this.name,
    required this.probability,
    required this.commonNames,
    required this.treatmentBiological,
    required this.treatmentChemical,
    required this.treatmentPrevention,
  });

  factory DiseaseDetail.fromMap(Map<String, dynamic> map) {
    return DiseaseDetail(
      name:                  map['name'] ?? '',
      probability:           map['probability']?.toString() ?? '0',
      commonNames:           map['common_names'] ?? '',
      treatmentBiological:   map['treatment_biological'] ?? '',
      treatmentChemical:     map['treatment_chemical'] ?? '',
      treatmentPrevention:   map['treatment_prevention'] ?? '',
    );
  }

  int get probabilityInt => int.tryParse(probability) ?? 0;
  bool get isHighRisk    => probabilityInt >= 70;
  bool get isMediumRisk  => probabilityInt >= 40 && probabilityInt < 70;
}