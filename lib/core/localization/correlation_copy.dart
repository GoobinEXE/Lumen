import 'package:noa/l10n/app_localizations.dart';

import '../../features/sleep_analytics/domain/correlation_engine.dart';

/// Adapta o catálogo gerado para o contrato sem Flutter do domínio.
class L10nCorrelationCopy implements CorrelationCopy {
  const L10nCorrelationCopy(this.l10n);

  final AppLocalizations l10n;

  @override
  String get insightCollectingTitle => l10n.insightCollectingTitle;

  @override
  String get insightCollectingDescHealth => l10n.insightCollectingDescHealth;

  @override
  String get insightCollectingAdvice => l10n.insightCollectingAdvice;

  @override
  String get insightRemParalysisTitle => l10n.insightRemParalysisTitle;

  @override
  String insightRemParalysisDesc(String percent) =>
      l10n.insightRemParalysisDesc(percent);

  @override
  String get insightRemParalysisAdvice => l10n.insightRemParalysisAdvice;

  @override
  String get insightMentalFlowTitle => l10n.insightMentalFlowTitle;

  @override
  String get insightMentalFlowDesc => l10n.insightMentalFlowDesc;

  @override
  String get insightMentalFlowAdvice => l10n.insightMentalFlowAdvice;

  @override
  String get insightSensoryTitle => l10n.insightSensoryTitle;

  @override
  String insightSensoryDesc(int count) => l10n.insightSensoryDesc(count);

  @override
  String get insightSensoryAdvice => l10n.insightSensoryAdvice;

  @override
  String get insightHrvTitle => l10n.insightHrvTitle;

  @override
  String insightHrvDesc(String percent) => l10n.insightHrvDesc(percent);

  @override
  String get insightHrvAdvice => l10n.insightHrvAdvice;

  @override
  String get insightMovementTitle => l10n.insightMovementTitle;

  @override
  String insightMovementDesc(String percent) =>
      l10n.insightMovementDesc(percent);

  @override
  String get insightMovementAdvice => l10n.insightMovementAdvice;

  @override
  String get insightDaylightTitle => l10n.insightDaylightTitle;

  @override
  String insightDaylightDesc(String percent) =>
      l10n.insightDaylightDesc(percent);

  @override
  String get insightDaylightAdvice => l10n.insightDaylightAdvice;

  @override
  String get insightNoiseTitle => l10n.insightNoiseTitle;

  @override
  String insightNoiseDesc(String percent) => l10n.insightNoiseDesc(percent);

  @override
  String get insightNoiseAdvice => l10n.insightNoiseAdvice;

  @override
  String get insightCollectingDescGeneric => l10n.insightCollectingDescGeneric;
}
