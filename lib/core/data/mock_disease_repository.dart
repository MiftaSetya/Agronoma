import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/disease.dart';

/// Diagnosis contoh dari [MockData].
///
/// Meniru waktu proses model: ada jeda supaya layar "menganalisis" benar-benar
/// terlihat dan terasa seperti sedang bekerja.
class MockDiseaseRepository implements DiseaseRepository {
  const MockDiseaseRepository();

  @override
  Future<Disease> detect({String? imagePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    return MockData.disease;
  }
}
