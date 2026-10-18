import 'package:frontend/core/models/disease.dart';

abstract class DiseaseRepository {
  Future<Disease> detect({String? imagePath, String? plantId});
}
