import Foundation
import ImageIO
import Vision

enum VisionOcrSupport {
  static let contractVersion: Int64 = 1

  static func matchedLanguages(
    preferred: [String],
    supported: [String]
  ) -> [String] {
    var matches: [String] = []
    for preference in preferred {
      let normalized = preference.replacingOccurrences(of: "_", with: "-").lowercased()
      guard !normalized.isEmpty else { continue }
      if let match = supported.first(where: { language in
        let candidate = language.replacingOccurrences(of: "_", with: "-").lowercased()
        return candidate == normalized
          || candidate.hasPrefix("\(normalized)-")
          || normalized.hasPrefix("\(candidate)-")
      }), !matches.contains(match) {
        matches.append(match)
      }
    }
    return matches
  }

  static func imageOrientation(from properties: [CFString: Any]?) -> CGImagePropertyOrientation {
    guard
      let rawValue = properties?[kCGImagePropertyOrientation] as? NSNumber,
      let orientation = CGImagePropertyOrientation(rawValue: rawValue.uint32Value)
    else {
      return .up
    }
    return orientation
  }
}

final class VisionOcrService: VisionOcrApi {
  private let recognitionQueue = DispatchQueue(
    label: "app.tripcost.vision-ocr",
    qos: .userInitiated,
    attributes: .concurrent
  )
  private let requestLock = NSLock()
  private var activeRequest: VNRecognizeTextRequest?

  func supportedRecognitionLanguages() throws -> [String] {
    let accurate = try Self.supportedLanguages(for: .accurate)
    let fast = try Self.supportedLanguages(for: .fast)
    return Array(Set(accurate + fast)).sorted()
  }

  func recognizeImage(
    request: OcrRequest,
    completion: @escaping (Result<OcrResult, Error>) -> Void
  ) {
    guard request.contractVersion == VisionOcrSupport.contractVersion else {
      completion(.failure(Self.error(
        code: "unsupported-contract",
        message: "Unsupported OCR contract version."
      )))
      return
    }

    let fileUrl = URL(fileURLWithPath: request.imagePath)
    guard FileManager.default.fileExists(atPath: fileUrl.path) else {
      completion(.failure(Self.error(
        code: "image-not-found",
        message: "The selected image is no longer available."
      )))
      return
    }

    recognitionQueue.async {
      do {
        guard
          let source = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
          throw Self.error(code: "invalid-image", message: "The selected file is not a readable image.")
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
          as? [CFString: Any]
        let orientation = VisionOcrSupport.imageOrientation(from: properties)

        let visionRequest = VNRecognizeTextRequest()
        visionRequest.recognitionLevel = request.mode == .fast ? .fast : .accurate
        visionRequest.usesLanguageCorrection = request.mode == .accurate
        let supported = try visionRequest.supportedRecognitionLanguages()
        let languages = VisionOcrSupport.matchedLanguages(
          preferred: request.preferredLanguages,
          supported: supported
        )
        if !languages.isEmpty {
          visionRequest.recognitionLanguages = languages
        }

        self.replaceActiveRequest(with: visionRequest)
        defer { self.clearActiveRequest(ifMatching: visionRequest) }

        let handler = VNImageRequestHandler(
          cgImage: image,
          orientation: orientation,
          options: [:]
        )
        do {
          try handler.perform([visionRequest])
        } catch let error as NSError where error.domain == VNErrorDomain
          && error.code == VNErrorCode.requestCancelled.rawValue {
          throw Self.error(code: "cancelled", message: "OCR was cancelled.")
        }

        let candidates = (visionRequest.results ?? []).compactMap { observation -> OcrCandidate? in
          guard let recognized = observation.topCandidates(1).first else { return nil }
          let box = observation.boundingBox
          return OcrCandidate(
            text: recognized.string,
            confidence: Double(recognized.confidence),
            x: box.origin.x,
            y: box.origin.y,
            width: box.width,
            height: box.height
          )
        }.sorted { left, right in
          if abs(left.y - right.y) > 0.01 { return left.y > right.y }
          return left.x < right.x
        }
        self.finish(
          completion,
          with: .success(OcrResult(
            contractVersion: VisionOcrSupport.contractVersion,
            candidates: candidates
          ))
        )
      } catch let error as PigeonError {
        self.finish(completion, with: .failure(error))
      } catch {
        self.finish(
          completion,
          with: .failure(Self.error(
            code: "recognition-failed",
            message: error.localizedDescription
          ))
        )
      }
    }
  }

  private func replaceActiveRequest(with request: VNRecognizeTextRequest) {
    requestLock.lock()
    activeRequest?.cancel()
    activeRequest = request
    requestLock.unlock()
  }

  private func clearActiveRequest(ifMatching request: VNRecognizeTextRequest) {
    requestLock.lock()
    if activeRequest === request {
      activeRequest = nil
    }
    requestLock.unlock()
  }

  private func finish(
    _ completion: @escaping (Result<OcrResult, Error>) -> Void,
    with result: Result<OcrResult, Error>
  ) {
    DispatchQueue.main.async { completion(result) }
  }

  private static func error(code: String, message: String) -> PigeonError {
    PigeonError(code: code, message: message, details: nil)
  }

  private static func supportedLanguages(
    for recognitionLevel: VNRequestTextRecognitionLevel
  ) throws -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = recognitionLevel
    return try request.supportedRecognitionLanguages()
  }
}
