import SwiftUI
import WidgetKit

struct WidgetSnapshotEnvelope: Decodable {
  let version: Int
  let generatedAtUtc: Date
  let rate: RateSummary?
  let trip: TripSummary?

  struct RateSummary: Decodable {
    let baseCurrency: String
    let quoteCurrency: String
    let amount: String
    let convertedAmount: String
    let rate: String
    let rateDate: String
    let isCached: Bool
    let isStale: Bool
  }

  struct TripSummary: Decodable {
    let name: String
    let homeCurrency: String
    let spent: String
    let budget: String?
  }
}

enum WidgetSnapshotReader {
  static func decode(_ data: Data) throws -> WidgetSnapshotEnvelope {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let value = try decoder.singleValueContainer().decode(String.self)
      let fractional = ISO8601DateFormatter()
      fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = fractional.date(from: value) {
        return date
      }
      if let date = ISO8601DateFormatter().date(from: value) {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: try decoder.singleValueContainer(),
        debugDescription: "Invalid ISO-8601 date."
      )
    }
    let value = try decoder.decode(WidgetSnapshotEnvelope.self, from: data)
    guard value.version == 1 else { throw CocoaError(.coderReadCorrupt) }
    return value
  }

  static func load(bundle: Bundle = .main) -> WidgetSnapshotEnvelope? {
    guard let identifier = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
          let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
          )
    else { return nil }
    let url = container.appendingPathComponent("widget_snapshot.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decode(data)
  }
}

struct TripCostEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshotEnvelope?
}

struct TripCostTimelineProvider: TimelineProvider {
  func placeholder(in _: Context) -> TripCostEntry {
    TripCostEntry(date: Date(), snapshot: nil)
  }

  func getSnapshot(in _: Context, completion: @escaping (TripCostEntry) -> Void) {
    completion(TripCostEntry(date: Date(), snapshot: WidgetSnapshotReader.load()))
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<TripCostEntry>) -> Void) {
    let entry = TripCostEntry(date: Date(), snapshot: WidgetSnapshotReader.load())
    let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date
    completion(Timeline(entries: [entry], policy: .after(refreshDate)))
  }
}

struct TripCostWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TripCostEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      if let rate = entry.snapshot?.rate {
        HStack {
          Image(systemName: "arrow.left.arrow.right")
          Text("\(rate.baseCurrency) / \(rate.quoteCurrency)").font(.headline)
          Spacer()
          if rate.isCached || rate.isStale {
            Image(systemName: rate.isStale ? "exclamationmark.clock" : "tray.and.arrow.down")
              .foregroundColor(rate.isStale ? .orange : .secondary)
              .accessibilityLabel(Text(rate.isStale ? "widget_stale" : "widget_cached"))
          }
        }
        Text("\(rate.amount) \(rate.baseCurrency) = \(rate.convertedAmount) \(rate.quoteCurrency)")
          .font(.title3.weight(.semibold))
          .minimumScaleFactor(0.75)
        Text("1 \(rate.baseCurrency) = \(rate.rate) \(rate.quoteCurrency) · \(rate.rateDate)")
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
      } else {
        Label("widget_empty", systemImage: "airplane.departure").font(.headline)
        Text("widget_open_app").font(.caption).foregroundColor(.secondary)
      }
      if family == .systemMedium, let trip = entry.snapshot?.trip {
        Divider()
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(trip.name).font(.subheadline.weight(.semibold)).lineLimit(1)
            Text("widget_trip_spent").font(.caption2).foregroundColor(.secondary)
          }
          Spacer()
          Text("\(trip.spent) \(trip.homeCurrency)").font(.subheadline.monospacedDigit())
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding()
  }
}

@main
struct AppWidget: Widget {
  private let kind = "AppWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TripCostTimelineProvider()) { entry in
      TripCostWidgetView(entry: entry)
    }
    .configurationDisplayName("widget_name")
    .description("widget_description")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
