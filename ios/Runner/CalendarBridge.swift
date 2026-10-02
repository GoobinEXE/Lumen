import Flutter
import EventKit

/// Ponte do calendário do iPhone. A UI não fala com o EventKit.
final class CalendarBridge: NSObject {
  static let channelName = "dev.prism.lumen/calendar_bridge"
  private let store = EKEventStore()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    let instance = CalendarBridge()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hasAccess":
      result(currentAccess())
    case "requestAccess":
      requestAccess(result: result)
    case "createEvent":
      createEvent(args: call.arguments as? [String: Any], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func currentAccess() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      return status == .fullAccess
    }
    return status == .authorized
  }

  private func requestAccess(result: @escaping FlutterResult) {
    if currentAccess() {
      result(true)
      return
    }
    let status = EKEventStore.authorizationStatus(for: .event)
    if status == .denied || status == .restricted {
      result(false)
      return
    }
    store.requestFullAccessToEvents { granted, _ in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }

  private func createEvent(args: [String: Any]?, result: @escaping FlutterResult) {
    guard currentAccess(),
          let args,
          let title = args["title"] as? String,
          let startMs = args["startMs"] as? NSNumber,
          let endMs = args["endMs"] as? NSNumber,
          let calendar = store.defaultCalendarForNewEvents
    else {
      result(nil)
      return
    }

    let event = EKEvent(eventStore: store)
    event.calendar = calendar
    event.title = title
    event.startDate = Date(timeIntervalSince1970: startMs.doubleValue / 1000)
    event.endDate = Date(timeIntervalSince1970: endMs.doubleValue / 1000)
    event.notes = args["notes"] as? String
    do {
      try store.save(event, span: .thisEvent)
      result(event.eventIdentifier)
    } catch {
      result(nil)
    }
  }
}
