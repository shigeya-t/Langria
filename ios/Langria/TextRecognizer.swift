import UIKit
import Vision

/// Reads the text in a photo on the device (Vision), so only the text, not the
/// image, is sent to the AI service.
enum TextRecognizer {
  static func recognize(_ image: UIImage) async throws -> String {
    guard let cgImage = image.cgImage else { return "" }
    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    return try await Task.detached(priority: .userInitiated) {
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      request.automaticallyDetectsLanguage = true
      try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
      return paragraphs(request.results ?? [])
    }.value
  }

  /// Vision returns one observation per line. Lines that sit right under each
  /// other with a similar height are joined back into paragraphs, so the model
  /// translates sentences rather than line fragments; a larger gap, a change
  /// of size or a jump sideways starts a new paragraph.
  private static func paragraphs(_ observations: [VNRecognizedTextObservation]) -> String {
    struct Line { let text: String; let box: CGRect }
    // Vision's boxes are normalized with the origin at the bottom left.
    let lines = observations.compactMap { observation -> Line? in
      guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
      return Line(text: text, box: observation.boundingBox)
    }.sorted { $0.box.maxY > $1.box.maxY }
    var result = ""
    var previous: Line?
    for line in lines {
      if let previous {
        let height = max(previous.box.height, line.box.height)
        let gap = previous.box.minY - line.box.maxY
        let similarSize = abs(previous.box.height - line.box.height) < height * 0.35
        let aligned = abs(previous.box.minX - line.box.minX) < height * 1.5 || line.box.minX >= previous.box.minX && line.box.maxX <= previous.box.maxX + height
        if gap < height * 0.8 && gap > -height * 0.5 && similarSize && aligned {
          result += separator(between: previous.text, and: line.text)
        } else {
          result += "\n"
        }
      }
      result += line.text
      previous = line
    }
    return result
  }

  // Words in scripts written with spaces are joined with one; CJK and Thai
  // text runs on.
  private static func separator(between first: String, and second: String) -> String {
    guard let last = first.unicodeScalars.last, let next = second.unicodeScalars.first else { return " " }
    let tight = { (scalar: Unicode.Scalar) in
      (0x3000...0x9FFF).contains(scalar.value) || (0xF900...0xFAFF).contains(scalar.value) || (0xFF00...0xFFEF).contains(scalar.value) || (0x0E00...0x0E7F).contains(scalar.value)
    }
    if tight(last) && tight(next) { return "" }
    return " "
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
