import SwiftUI
import WidgetKit

struct WidgetSnapshotEnvelope: Decodable {
  let version: Int
  let generatedAtUtc: Date
  let languageCode: String?
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
    let expenseCount: Int?
    let latestExpenseTitle: String?
    let latestExpenseAmount: String?
    let isUnassigned: Bool?
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
    Group {
      if let trip = entry.snapshot?.trip {
        spendingView(trip, rate: entry.snapshot?.rate)
      } else if let rate = entry.snapshot?.rate {
        rateView(rate)
      } else {
        emptyView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .tripCostWidgetContentMargins()
    .tripCostWidgetBackground()
  }

  private var accent: Color { Color(red: 0.09, green: 0.42, blue: 0.36) }
  private var strings: WidgetStrings {
    WidgetStrings(languageCode: entry.snapshot?.languageCode)
  }

  @ViewBuilder
  private func spendingView(
    _ trip: WidgetSnapshotEnvelope.TripSummary,
    rate: WidgetSnapshotEnvelope.RateSummary?
  ) -> some View {
    if family == .systemMedium {
      mediumSpendingView(trip, rate: rate)
    } else {
      compactSpendingView(trip)
    }
  }

  private func compactSpendingView(
    _ trip: WidgetSnapshotEnvelope.TripSummary
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      compactSpendingHeader(trip)

      Spacer(minLength: 5)

      Text("\(trip.spent) \(trip.homeCurrency)")
        .font(.system(size: 27, weight: .bold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.65)
      spentLabel(trip)

      Spacer(minLength: 6)

      if let budget = trip.budget, let progress = budgetProgress(spent: trip.spent, budget: budget) {
        VStack(spacing: 4) {
          HStack {
            Text(verbatim: strings.value("widget_budget"))
            Spacer()
            Text("\(budget) \(trip.homeCurrency)")
          }
          .font(.caption2)
          .foregroundColor(.secondary)
          ProgressView(value: progress)
            .tint(accent)
        }
      } else if let latestTitle = trip.latestExpenseTitle {
        HStack(spacing: 5) {
          Image(systemName: "clock.arrow.circlepath")
          Text(verbatim: strings.value("widget_latest"))
          Text(latestTitle)
            .lineLimit(1)
            .layoutPriority(1)
          Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundColor(.secondary)
      }
    }
  }

  private func mediumSpendingView(
    _ trip: WidgetSnapshotEnvelope.TripSummary,
    rate: WidgetSnapshotEnvelope.RateSummary?
  ) -> some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 0) {
        spendingHeader(trip)
        Spacer(minLength: 6)
        Text("\(trip.spent) \(trip.homeCurrency)")
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.65)
        spentLabel(trip)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Divider()

      VStack(alignment: .leading, spacing: 7) {
        if let latestTitle = trip.latestExpenseTitle {
          VStack(alignment: .leading, spacing: 2) {
            Text(latestTitle)
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
            if let latestAmount = trip.latestExpenseAmount {
              Text("\(latestAmount) \(trip.homeCurrency)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            }
          }
        }
        if let budget = trip.budget,
           let progress = budgetProgress(spent: trip.spent, budget: budget) {
          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
              Text(verbatim: strings.value("widget_budget"))
              Text("· \(budget) \(trip.homeCurrency)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
            ProgressView(value: progress)
              .tint(accent)
          }
        }
        Spacer(minLength: 0)
        if let rate {
          VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
              Text("1 \(rate.baseCurrency)")
              if rate.isStale {
                Image(systemName: "exclamationmark.clock")
                  .foregroundColor(.orange)
                  .accessibilityLabel(Text(verbatim: strings.value("widget_stale")))
              }
            }
            Text("≈ \(rate.rate) \(rate.quoteCurrency)")
              .font(.caption.monospacedDigit().weight(.medium))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .foregroundColor(.primary)
          }
          .font(.caption2)
          .foregroundColor(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func compactSpendingHeader(
    _ trip: WidgetSnapshotEnvelope.TripSummary
  ) -> some View {
    HStack(spacing: 7) {
      Image(systemName: trip.isUnassigned == true ? "creditcard.fill" : "airplane")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(accent)
        .frame(width: 24, height: 24)
        .background(accent.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 0) {
        Group {
          if trip.isUnassigned == true {
            Text(verbatim: strings.value("widget_recent_spending"))
          } else {
            Text(trip.name)
          }
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        Text(expenseCountText(trip.expenseCount ?? 0))
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
      .layoutPriority(1)
      Spacer(minLength: 0)
    }
  }

  private func spendingHeader(
    _ trip: WidgetSnapshotEnvelope.TripSummary
  ) -> some View {
    HStack(spacing: 9) {
      Image(systemName: trip.isUnassigned == true ? "creditcard.fill" : "airplane")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(accent)
        .frame(width: 28, height: 28)
        .background(accent.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 1) {
        Group {
          if trip.isUnassigned == true {
            Text(verbatim: strings.value("widget_recent_spending"))
          } else {
            Text(trip.name)
          }
        }
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Text(expenseCountText(trip.expenseCount ?? 0))
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      Spacer(minLength: 4)
    }
  }

  @ViewBuilder
  private func spentLabel(_ trip: WidgetSnapshotEnvelope.TripSummary) -> some View {
    Group {
      if trip.isUnassigned == true {
        Text(verbatim: strings.value("widget_total_spent"))
      } else {
        Text(verbatim: strings.value("widget_trip_spent"))
      }
    }
    .font(.caption)
    .foregroundColor(.secondary)
  }

  private func rateView(_ rate: WidgetSnapshotEnvelope.RateSummary) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 7) {
        Image(systemName: "arrow.left.arrow.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(accent)
          .frame(width: 28, height: 28)
          .background(accent.opacity(0.12), in: Circle())
        Text("\(rate.baseCurrency) / \(rate.quoteCurrency)")
          .font(.system(size: family == .systemSmall ? 15 : 17, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .allowsTightening(true)
          .layoutPriority(1)
        Spacer(minLength: 0)
      }
      Spacer(minLength: 6)
      Text("1 \(rate.baseCurrency)")
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.secondary)
      Text("≈ \(rate.rate) \(rate.quoteCurrency)")
        .font(.system(size: 22, weight: .bold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.65)
      Spacer(minLength: 6)
      Text(rate.rateDate)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }

  private var emptyView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: "airplane.circle.fill")
        .font(.title)
        .foregroundColor(accent)
      Text(verbatim: strings.value("widget_empty")).font(.headline)
      Text(verbatim: strings.value("widget_open_app"))
        .font(.caption)
        .foregroundColor(.secondary)
      Spacer(minLength: 0)
    }
  }

  private func expenseCountText(_ count: Int) -> String {
    String(format: strings.value("widget_expense_count"), count)
  }

  private func budgetProgress(spent: String, budget: String) -> Double? {
    guard let spentValue = Double(spent),
          let budgetValue = Double(budget),
          budgetValue > 0
    else { return nil }
    return min(max(spentValue / budgetValue, 0), 1)
  }
}

private struct WidgetStrings {
  private let bundle: Bundle

  init(languageCode: String?) {
    let resourceName: String? = switch languageCode?.lowercased() {
    case "zh", "zh-hans": "zh-Hans"
    case "en": "en"
    default: nil
    }
    if let resourceName,
       let path = Bundle.main.path(forResource: resourceName, ofType: "lproj"),
       let localizedBundle = Bundle(path: path) {
      bundle = localizedBundle
    } else {
      bundle = .main
    }
  }

  func value(_ key: String) -> String {
    NSLocalizedString(key, bundle: bundle, comment: "")
  }
}

private extension View {
  @ViewBuilder
  func tripCostWidgetContentMargins() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self
    } else {
      padding()
    }
  }

  @ViewBuilder
  func tripCostWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        LinearGradient(
          colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    } else {
      background(
        LinearGradient(
          colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }
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
