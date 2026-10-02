import Flutter
import HealthKit
import UIKit

/// Ponte MethodChannel para tipos HealthKit fora do plugin `health`.
final class HealthKitBridge: NSObject {
  static let channelName = "dev.prism.lumen/healthkit_bridge"
  private let store = HKHealthStore()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = HealthKitBridge()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      requestAuthorization(result: result)
    case "writeStateOfMind":
      writeStateOfMind(args: call.arguments as? [String: Any], result: result)
    case "readStateOfMind":
      readStateOfMind(args: call.arguments as? [String: Any], result: result)
    case "readTimeInDaylight":
      if #available(iOS 17.0, *) {
        readQuantityDaily(
          identifier: .timeInDaylight,
          unit: HKUnit.minute(),
          cumulative: true,
          args: call.arguments as? [String: Any],
          result: result
        )
      } else {
        result([:])
      }
    case "readEnvironmentalAudio":
      readQuantityDaily(
        identifier: .environmentalAudioExposure,
        unit: HKUnit.decibelAWeightedSoundPressureLevel(),
        cumulative: false,
        args: call.arguments as? [String: Any],
        result: result
      )
    case "readHeadphoneAudio":
      readQuantityDaily(
        identifier: .headphoneAudioExposure,
        unit: HKUnit.decibelAWeightedSoundPressureLevel(),
        cumulative: false,
        args: call.arguments as? [String: Any],
        result: result
      )
    case "readMedications":
      readMedications(result: result)
    case "readDoseEvents":
      readDoseEvents(args: call.arguments as? [String: Any], result: result)
    case "writeDoseEvent":
      writeDoseEvent(args: call.arguments as? [String: Any], result: result)
    case "isMedicationsApiAvailable":
      result(medicationsApiAvailable())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Auth

  private func requestAuthorization(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    var readTypes = Set<HKObjectType>()
    var shareTypes = Set<HKSampleType>()

    if #available(iOS 18.0, *) {
      let som = HKObjectType.stateOfMindType()
      readTypes.insert(som)
      if let sampleType = som as? HKSampleType {
        shareTypes.insert(sampleType)
      }
    }

    if #available(iOS 17.0, *) {
      if let daylight = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) {
        readTypes.insert(daylight)
      }
    }
    if let audio = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) {
      readTypes.insert(audio)
    }
    if let headphone = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) {
      readTypes.insert(headphone)
    }

    store.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
      if let error {
        NSLog("[HealthKitBridge] auth error: \(error.localizedDescription)")
      }
      // Também tenta per-object auth de medicamentos quando disponível.
      self.requestMedicationsPerObjectAuthIfNeeded {
        result(success)
      }
    }
  }

  // MARK: - Medications

  /// Medications API (WWDC25 / iOS 26+) — stub seguro até o SDK do Xcode
  /// expor tipos estáveis no target do Runner. A UI Dart trata lista vazia.
  private func readMedications(result: @escaping FlutterResult) {
    result([])
  }

  private func readDoseEvents(args: [String: Any]?, result: @escaping FlutterResult) {
    result([])
  }

  private func writeDoseEvent(args: [String: Any]?, result: @escaping FlutterResult) {
    // Escrita de dose por apps de terceiros ainda não está estável na API pública.
    result(false)
  }

  private func medicationsApiAvailable() -> Bool {
    // Quando o SDK incluir HKUserAnnotatedMedication, ligar este flag.
    false
  }

  private func requestMedicationsPerObjectAuthIfNeeded(completion: @escaping () -> Void) {
    completion()
  }

  // MARK: - State of Mind

  private func writeStateOfMind(args: [String: Any]?, result: @escaping FlutterResult) {
    guard #available(iOS 18.0, *) else {
      result(false)
      return
    }
    guard let args,
          let valence = args["valence"] as? Double,
          let timestampMs = args["timestampMs"] as? Int
    else {
      result(false)
      return
    }

    let kindStr = args["kind"] as? String ?? "dailyMood"
    let kind: HKStateOfMind.Kind = kindStr == "momentary" ? .momentaryEmotion : .dailyMood
    let labels = Self.mapLabels(args["labels"] as? [String] ?? [])
    let associations = Self.mapAssociations(args["associations"] as? [String] ?? [])
    let date = Date(timeIntervalSince1970: Double(timestampMs) / 1000.0)

    let sample = HKStateOfMind(
      date: date,
      kind: kind,
      valence: valence,
      labels: labels,
      associations: associations
    )

    store.save(sample) { success, error in
      if let error {
        NSLog("[HealthKitBridge] writeStateOfMind: \(error.localizedDescription)")
      }
      result(success)
    }
  }

  private func readStateOfMind(args: [String: Any]?, result: @escaping FlutterResult) {
    guard #available(iOS 18.0, *) else {
      result([])
      return
    }
    guard let args,
          let startMs = args["startMs"] as? Int,
          let endMs = args["endMs"] as? Int
    else {
      result([])
      return
    }

    let start = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
    let end = Date(timeIntervalSince1970: Double(endMs) / 1000.0)
    let type = HKObjectType.stateOfMindType()
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

    let query = HKSampleQuery(
      sampleType: type,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [sort]
    ) { _, samples, error in
      if let error {
        NSLog("[HealthKitBridge] readStateOfMind: \(error.localizedDescription)")
        result([])
        return
      }
      let mapped: [[String: Any]] = (samples as? [HKStateOfMind] ?? []).map { sample in
        [
          "kind": sample.kind == .momentaryEmotion ? "momentary" : "dailyMood",
          "valence": sample.valence,
          "labels": sample.labels.map { Self.labelId($0) },
          "associations": sample.associations.map { Self.associationId($0) },
          "timestampMs": Int(sample.startDate.timeIntervalSince1970 * 1000),
        ]
      }
      result(mapped)
    }
    store.execute(query)
  }

  // MARK: - Quantity daily aggregates

  private func readQuantityDaily(
    identifier: HKQuantityTypeIdentifier,
    unit: HKUnit,
    cumulative: Bool,
    args: [String: Any]?,
    result: @escaping FlutterResult
  ) {
    guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier),
          let args,
          let startMs = args["startMs"] as? Int,
          let endMs = args["endMs"] as? Int
    else {
      result([:])
      return
    }

    let start = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
    let end = Date(timeIntervalSince1970: Double(endMs) / 1000.0)
    var interval = DateComponents()
    interval.day = 1

    let query = HKStatisticsCollectionQuery(
      quantityType: quantityType,
      quantitySamplePredicate: HKQuery.predicateForSamples(
        withStart: start,
        end: end,
        options: .strictStartDate
      ),
      options: cumulative ? .cumulativeSum : .discreteAverage,
      anchorDate: Calendar.current.startOfDay(for: start),
      intervalComponents: interval
    )

    query.initialResultsHandler = { _, collection, error in
      if let error {
        NSLog("[HealthKitBridge] quantity \(identifier.rawValue): \(error.localizedDescription)")
        result([:])
        return
      }
      var out: [String: Double] = [:]
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd"

      collection?.enumerateStatistics(from: start, to: end) { stats, _ in
        let key = formatter.string(from: stats.startDate)
        if cumulative {
          if let sum = stats.sumQuantity()?.doubleValue(for: unit) {
            out[key] = sum
          }
        } else if let avg = stats.averageQuantity()?.doubleValue(for: unit) {
          out[key] = avg
        }
      }
      result(out)
    }
    store.execute(query)
  }

  // MARK: - Mapping helpers

  @available(iOS 18.0, *)
  private static func mapLabels(_ ids: [String]) -> [HKStateOfMind.Label] {
    ids.compactMap { id in
      switch id {
      case "amazed": return .amazed
      case "amused": return .amused
      case "angry": return .angry
      case "annoyed": return .annoyed
      case "anxious": return .anxious
      case "ashamed": return .ashamed
      case "brave": return .brave
      case "calm": return .calm
      case "confident": return .confident
      case "content": return .content
      case "disappointed": return .disappointed
      case "discouraged": return .discouraged
      case "disgusted": return .disgusted
      case "drained": return .drained
      case "embarrassed": return .embarrassed
      case "excited": return .excited
      case "frustrated": return .frustrated
      case "grateful": return .grateful
      case "guilty": return .guilty
      case "happy": return .happy
      case "hopeful": return .hopeful
      case "hopeless": return .hopeless
      case "indifferent": return .indifferent
      case "irritated": return .irritated
      case "jealous": return .jealous
      case "joyful": return .joyful
      case "lonely": return .lonely
      case "overwhelmed": return .overwhelmed
      case "passionate": return .passionate
      case "peaceful": return .peaceful
      case "proud": return .proud
      case "relieved": return .relieved
      case "sad": return .sad
      case "satisfied": return .satisfied
      case "scared": return .scared
      case "stressed": return .stressed
      case "surprised": return .surprised
      case "worried": return .worried
      default: return nil
      }
    }
  }

  @available(iOS 18.0, *)
  private static func labelId(_ label: HKStateOfMind.Label) -> String {
    switch label {
    case .amazed: return "amazed"
    case .amused: return "amused"
    case .angry: return "angry"
    case .annoyed: return "annoyed"
    case .anxious: return "anxious"
    case .ashamed: return "ashamed"
    case .brave: return "brave"
    case .calm: return "calm"
    case .confident: return "confident"
    case .content: return "content"
    case .disappointed: return "disappointed"
    case .discouraged: return "discouraged"
    case .disgusted: return "disgusted"
    case .drained: return "drained"
    case .embarrassed: return "embarrassed"
    case .excited: return "excited"
    case .frustrated: return "frustrated"
    case .grateful: return "grateful"
    case .guilty: return "guilty"
    case .happy: return "happy"
    case .hopeful: return "hopeful"
    case .hopeless: return "hopeless"
    case .indifferent: return "indifferent"
    case .irritated: return "irritated"
    case .jealous: return "jealous"
    case .joyful: return "joyful"
    case .lonely: return "lonely"
    case .overwhelmed: return "overwhelmed"
    case .passionate: return "passionate"
    case .peaceful: return "peaceful"
    case .proud: return "proud"
    case .relieved: return "relieved"
    case .sad: return "sad"
    case .satisfied: return "satisfied"
    case .scared: return "scared"
    case .stressed: return "stressed"
    case .surprised: return "surprised"
    case .worried: return "worried"
    @unknown default: return "unknown"
    }
  }

  @available(iOS 18.0, *)
  private static func mapAssociations(_ ids: [String]) -> [HKStateOfMind.Association] {
    ids.compactMap { id in
      switch id {
      case "community": return .community
      case "currentEvents": return .currentEvents
      case "dating": return .dating
      case "education": return .education
      case "family": return .family
      case "fitness": return .fitness
      case "friends": return .friends
      case "health": return .health
      case "hobbies": return .hobbies
      case "identity": return .identity
      case "money": return .money
      case "partner": return .partner
      case "selfCare": return .selfCare
      case "spirituality": return .spirituality
      case "tasks": return .tasks
      case "travel": return .travel
      case "weather": return .weather
      case "work": return .work
      default: return nil
      }
    }
  }

  @available(iOS 18.0, *)
  private static func associationId(_ association: HKStateOfMind.Association) -> String {
    switch association {
    case .community: return "community"
    case .currentEvents: return "currentEvents"
    case .dating: return "dating"
    case .education: return "education"
    case .family: return "family"
    case .fitness: return "fitness"
    case .friends: return "friends"
    case .health: return "health"
    case .hobbies: return "hobbies"
    case .identity: return "identity"
    case .money: return "money"
    case .partner: return "partner"
    case .selfCare: return "selfCare"
    case .spirituality: return "spirituality"
    case .tasks: return "tasks"
    case .travel: return "travel"
    case .weather: return "weather"
    case .work: return "work"
    @unknown default: return "unknown"
    }
  }
}
