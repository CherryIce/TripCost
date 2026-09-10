import CloudKit
import Foundation
import WidgetKit

enum CloudSyncSupport {
  static let contractVersion: Int64 = 1
  static let minimumSupportedRecordSchemaVersion: Int64 = 1
  static let recordSchemaVersion: Int64 = 2
  static let zoneName = "TripCostSyncZoneV1"
  static let subscriptionID = "TripCostSyncZoneSubscriptionV1"
  static let recordType = "TCEntity"
  static let maximumPayloadBytes = 900_000

  static func validate(_ record: SyncRecord) throws {
    guard record.contractVersion == contractVersion else {
      throw PigeonError(
        code: "unsupported-contract",
        message: "Unsupported Cloud sync contract version.",
        details: nil
      )
    }
    guard (minimumSupportedRecordSchemaVersion...recordSchemaVersion)
      .contains(record.schemaVersion)
    else {
      throw PigeonError(
        code: "unsupported-record-schema",
        message: "Unsupported Cloud record schema version.",
        details: nil
      )
    }
    let allowedTypes = ["rateSnapshot", "paymentMethod", "trip", "expense", "userSettings"]
    guard allowedTypes.contains(record.recordType),
          !record.id.isEmpty,
          !record.deviceId.isEmpty,
          !record.changeId.isEmpty,
          ISO8601DateFormatter().date(from: record.modifiedAtUtc) != nil,
          let payload = record.payloadJson.data(using: .utf8),
          payload.count <= maximumPayloadBytes,
          let object = try? JSONSerialization.jsonObject(with: payload),
          let dictionary = object as? [String: Any],
          dictionary["receipt_local_path"] == nil
    else {
      throw PigeonError(
        code: "invalid-record",
        message: "Cloud sync record validation failed.",
        details: nil
      )
    }
  }

  static func recordName(type: String, id: String) -> String {
    "\(type)__\(id)"
  }

  static func parseRecordName(_ value: String) -> (String, String)? {
    guard let separator = value.range(of: "__") else { return nil }
    let type = String(value[..<separator.lowerBound])
    let id = String(value[separator.upperBound...])
    return type.isEmpty || id.isEmpty ? nil : (type, id)
  }

  static func incomingWins(_ incoming: SyncRecord, over existing: CKRecord) -> Bool {
    guard let incomingDate = ISO8601DateFormatter().date(from: incoming.modifiedAtUtc),
          let existingModifiedAt = existing["modifiedAtUtc"] as? String,
          let existingDate = ISO8601DateFormatter().date(from: existingModifiedAt),
          let existingChangeID = existing["changeId"] as? String
    else {
      return true
    }
    if incomingDate != existingDate {
      return incomingDate > existingDate
    }
    return incoming.changeId > existingChangeID
  }

  static func encodeToken(_ token: CKServerChangeToken) throws -> String {
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: token,
      requiringSecureCoding: true
    )
    return data.base64EncodedString()
  }

  static func decodeToken(_ value: String?) throws -> CKServerChangeToken? {
    guard let value, !value.isEmpty else { return nil }
    guard let data = Data(base64Encoded: value) else {
      throw PigeonError(code: "invalid-cursor", message: "Invalid Cloud sync cursor.", details: nil)
    }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKServerChangeToken.self,
        from: data
      )
    } catch {
      throw PigeonError(code: "invalid-cursor", message: "Invalid Cloud sync cursor.", details: nil)
    }
  }

  static func mappedError(_ error: Error) -> PigeonError {
    if let value = error as? PigeonError { return value }
    guard let cloudError = error as? CKError else {
      return PigeonError(code: "cloud-unknown", message: "Cloud sync failed.", details: nil)
    }
    let code: String
    switch cloudError.code {
    case .notAuthenticated:
      code = "icloud-no-account"
    case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
      code = "cloud-network"
    case .quotaExceeded:
      code = "cloud-quota-exceeded"
    case .changeTokenExpired:
      code = "cloud-cursor-expired"
    case .zoneNotFound, .userDeletedZone:
      code = "cloud-zone-missing"
    case .permissionFailure, .managedAccountRestricted:
      code = "cloud-restricted"
    default:
      code = "cloud-operation-failed"
    }
    return PigeonError(code: code, message: "Cloud sync failed.", details: nil)
  }
}

final class PlatformApiStubs: CloudSyncApi, SharedSnapshotApi, WidgetControlApi {
  private let bundle: Bundle
  private lazy var container: CKContainer = {
    if let identifier = bundle.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String,
       !identifier.isEmpty
    {
      return CKContainer(identifier: identifier)
    }
    return CKContainer.default()
  }()
  private lazy var database: CKDatabase = container.privateCloudDatabase
  private let zoneID = CKRecordZone.ID(
    zoneName: CloudSyncSupport.zoneName,
    ownerName: CKCurrentUserDefaultName
  )

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  func accountStatus(
    completion: @escaping (Result<CloudAccountState, Error>) -> Void
  ) {
    Task {
      do {
        let status = try await container.accountStatus()
        let value: CloudAccountState
        switch status {
        case .available: value = .available
        case .noAccount: value = .noAccount
        case .restricted, .temporarilyUnavailable: value = .restricted
        case .couldNotDetermine: value = .couldNotDetermine
        @unknown default: value = .couldNotDetermine
        }
        completion(.success(value))
      } catch {
        completion(.failure(CloudSyncSupport.mappedError(error)))
      }
    }
  }

  func pushChanges(
    records: [SyncRecord],
    cursor _: String?,
    completion: @escaping (Result<SyncPushResult, Error>) -> Void
  ) {
    Task {
      do {
        guard records.count <= 200 else {
          throw PigeonError(code: "batch-too-large", message: "Cloud batch exceeds 200 records.", details: nil)
        }
        for record in records { try CloudSyncSupport.validate(record) }
        try await ensureZoneAndSubscription()
        let ids = records.map {
          CKRecord.ID(
            recordName: CloudSyncSupport.recordName(type: $0.recordType, id: $0.id),
            zoneID: zoneID
          )
        }
        let existing = try await database.records(for: ids)
        var cloudRecords: [CKRecord] = []
        var accepted: [String] = []
        for (index, value) in records.enumerated() {
          let id = ids[index]
          let cloudRecord: CKRecord
          if let result = existing[id], case .success(let fetched) = result {
            if !CloudSyncSupport.incomingWins(value, over: fetched) {
              accepted.append("\(value.recordType):\(value.id)")
              continue
            }
            cloudRecord = fetched
          } else {
            cloudRecord = CKRecord(recordType: CloudSyncSupport.recordType, recordID: id)
          }
          cloudRecord["entityType"] = value.recordType as CKRecordValue
          cloudRecord["entityId"] = value.id as CKRecordValue
          cloudRecord["payloadJson"] = value.payloadJson as CKRecordValue
          cloudRecord["modifiedAtUtc"] = value.modifiedAtUtc as CKRecordValue
          cloudRecord["deleted"] = NSNumber(value: value.deleted)
          cloudRecord["schemaVersion"] = NSNumber(value: value.schemaVersion)
          cloudRecord["deviceId"] = value.deviceId as CKRecordValue
          cloudRecord["changeId"] = value.changeId as CKRecordValue
          cloudRecords.append(cloudRecord)
        }
        if cloudRecords.isEmpty {
          completion(.success(SyncPushResult(
            contractVersion: CloudSyncSupport.contractVersion,
            acceptedRecordIds: accepted,
            cursor: nil
          )))
          return
        }
        let result = try await database.modifyRecords(
          saving: cloudRecords,
          deleting: [],
          savePolicy: .changedKeys,
          atomically: false
        )
        var firstError: Error?
        for value in records {
          let id = CKRecord.ID(
            recordName: CloudSyncSupport.recordName(type: value.recordType, id: value.id),
            zoneID: zoneID
          )
          if let save = result.saveResults[id] {
            switch save {
            case .success:
              accepted.append("\(value.recordType):\(value.id)")
            case .failure(let error):
              firstError = firstError ?? error
            }
          }
        }
        if accepted.isEmpty, let firstError {
          throw firstError
        }
        completion(.success(SyncPushResult(
          contractVersion: CloudSyncSupport.contractVersion,
          acceptedRecordIds: accepted,
          cursor: nil
        )))
      } catch {
        completion(.failure(CloudSyncSupport.mappedError(error)))
      }
    }
  }

  func pullChanges(
    cursor: String?,
    completion: @escaping (Result<SyncPullResult, Error>) -> Void
  ) {
    Task {
      do {
        try await ensureZoneAndSubscription()
        let token = try CloudSyncSupport.decodeToken(cursor)
        let result = try await database.recordZoneChanges(
          inZoneWith: zoneID,
          since: token,
          desiredKeys: nil,
          resultsLimit: 200
        )
        var records: [SyncRecord] = []
        for modificationResult in result.modificationResultsByID.values {
          guard case .success(let modification) = modificationResult else { continue }
          let cloudRecord = modification.record
          guard let entityType = cloudRecord["entityType"] as? String,
                let entityId = cloudRecord["entityId"] as? String,
                let payload = cloudRecord["payloadJson"] as? String,
                let modifiedAt = cloudRecord["modifiedAtUtc"] as? String,
                let deleted = cloudRecord["deleted"] as? NSNumber,
                let schemaVersion = cloudRecord["schemaVersion"] as? NSNumber,
                let deviceId = cloudRecord["deviceId"] as? String,
                let changeId = cloudRecord["changeId"] as? String
          else {
            continue
          }
          let record = SyncRecord(
            contractVersion: CloudSyncSupport.contractVersion,
            id: entityId,
            recordType: entityType,
            schemaVersion: schemaVersion.int64Value,
            deviceId: deviceId,
            changeId: changeId,
            payloadJson: payload,
            modifiedAtUtc: modifiedAt,
            deleted: deleted.boolValue
          )
          try CloudSyncSupport.validate(record)
          records.append(record)
        }
        let now = ISO8601DateFormatter().string(from: Date())
        for deletion in result.deletions {
          guard let (entityType, entityId) = CloudSyncSupport.parseRecordName(
            deletion.recordID.recordName
          ) else { continue }
          records.append(SyncRecord(
            contractVersion: CloudSyncSupport.contractVersion,
            id: entityId,
            recordType: entityType,
            schemaVersion: CloudSyncSupport.recordSchemaVersion,
            deviceId: "cloudkit",
            changeId: "hard-delete-\(deletion.recordID.recordName)",
            payloadJson: "{\"id\":\"\(entityId)\"}",
            modifiedAtUtc: now,
            deleted: true
          ))
        }
        completion(.success(SyncPullResult(
          contractVersion: CloudSyncSupport.contractVersion,
          records: records,
          cursor: try CloudSyncSupport.encodeToken(result.changeToken),
          hasMore: result.moreComing
        )))
      } catch {
        completion(.failure(CloudSyncSupport.mappedError(error)))
      }
    }
  }

  func writeWidgetSnapshot(
    snapshot: SharedSnapshot,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      guard snapshot.contractVersion == 1,
            let data = snapshot.payloadJson.data(using: .utf8),
            (try JSONSerialization.jsonObject(with: data)) is [String: Any]
      else {
        throw PigeonError(code: "invalid-snapshot", message: "Invalid Widget snapshot.", details: nil)
      }
      let url = try widgetSnapshotURL()
      try data.write(to: url, options: .atomic)
      WidgetCenter.shared.reloadTimelines(ofKind: "AppWidget")
      completion(.success(()))
    } catch {
      NSLog("TripCost widget snapshot write failed: %@", error.localizedDescription)
      completion(.failure(error))
    }
  }

  func clearWidgetSnapshot(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      let url = try widgetSnapshotURL()
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "AppWidget")
      completion(.success(()))
    } catch {
      completion(.failure(error))
    }
  }

  func reloadTimelines() throws {
    WidgetCenter.shared.reloadTimelines(ofKind: "AppWidget")
  }

  private func ensureZoneAndSubscription() async throws {
    do {
      _ = try await database.recordZone(for: zoneID)
    } catch let error as CKError where error.code == .zoneNotFound {
      _ = try await database.save(CKRecordZone(zoneID: zoneID))
    }
    do {
      _ = try await database.subscription(for: CloudSyncSupport.subscriptionID)
    } catch let error as CKError where error.code == .unknownItem {
      let subscription = CKRecordZoneSubscription(
        zoneID: zoneID,
        subscriptionID: CloudSyncSupport.subscriptionID
      )
      let notificationInfo = CKSubscription.NotificationInfo()
      notificationInfo.shouldSendContentAvailable = true
      subscription.notificationInfo = notificationInfo
      _ = try await database.save(subscription)
    }
  }

  private func widgetSnapshotURL() throws -> URL {
    guard let identifier = Bundle.main.object(
      forInfoDictionaryKey: "AppGroupIdentifier"
    ) as? String,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: identifier
      )
    else {
      throw PigeonError(code: "app-group-unavailable", message: "App Group is unavailable.", details: nil)
    }
    return container.appendingPathComponent("widget_snapshot.json", isDirectory: false)
  }
}
