import '../../../integrations/health/models/health_demographics.dart';
import 'profile_demographics.dart';

/// Ponte do modelo da integração de saúde para o domínio do perfil.
extension HealthDemographicsMapper on HealthDemographics {
  ProfileDemographics toProfileDemographics() {
    return ProfileDemographics(
      birthDate: birthDate,
      weightKg: weightKg,
      heightCm: heightCm,
      biologicalSex: biologicalSex?.code,
    );
  }
}
