import Foundation

enum SeoulBusAPIError: Error, Equatable, Sendable {
  case missingServiceKey
  case invalidURL
  case invalidResponse
  case invalidStatusCode(Int)
  case apiFailure(code: String, message: String)
  case malformedResponse(String)
  case invalidField(String)
}

struct SeoulBusAPIResponse: Equatable, Sendable {
  let header: [String: String]
  let items: [[String: String]]
}

enum SeoulBusAPITransport {
  static func fetch(
    path: String,
    parameters: [(name: String, value: String)]
  ) async throws -> SeoulBusAPIResponse {
    var components = URLComponents()
    components.scheme = "http"
    components.host = "ws.bus.go.kr"
    components.path = path
    components.percentEncodedQuery = parameters
      .map { "\($0.name)=\(percentEncodedQueryValue($0.value))" }
      .joined(separator: "&")

    guard let url = components.url else {
      throw SeoulBusAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 15

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw SeoulBusAPIError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw SeoulBusAPIError.invalidStatusCode(httpResponse.statusCode)
    }

    let apiResponse = try SeoulBusAPIXMLParser.parse(data)
    let resultCode = apiResponse.header["headerCd"]
      ?? apiResponse.header["resultCode"]
      ?? apiResponse.header["returnReasonCode"]
    let resultMessage = apiResponse.header["headerMsg"]
      ?? apiResponse.header["resultMessage"]
      ?? apiResponse.header["returnAuthMsg"]
      ?? ""

    guard let resultCode else {
      throw SeoulBusAPIError.malformedResponse("Missing result code.")
    }
    guard resultCode == "0" || resultCode == "00" else {
      throw SeoulBusAPIError.apiFailure(code: resultCode, message: resultMessage)
    }

    return apiResponse
  }

  static func serviceKey() throws -> String {
    let serviceKey = Secrets.serviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw SeoulBusAPIError.missingServiceKey
    }

    return serviceKey
  }

  private static func percentEncodedQueryValue(_ value: String) -> String {
    if value.contains("%") {
      return value
    }

    var allowedCharacters = CharacterSet.urlQueryAllowed
    allowedCharacters.remove(charactersIn: "&=+")

    return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
  }
}

struct SeoulBusAPIFields {
  let values: [String: String]

  func string(_ name: String) -> String {
    values[name]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  func requiredInt(_ name: String) throws -> Int {
    guard let value = Int(string(name)) else {
      throw SeoulBusAPIError.invalidField(name)
    }

    return value
  }

  func optionalInt(_ name: String) -> Int? {
    Int(string(name))
  }

  func requiredDouble(_ name: String) throws -> Double {
    guard let value = Double(string(name)) else {
      throw SeoulBusAPIError.invalidField(name)
    }

    return value
  }
}

private enum SeoulBusAPIXMLParser {
  static func parse(_ data: Data) throws -> SeoulBusAPIResponse {
    let delegate = Delegate()
    let parser = XMLParser(data: data)
    parser.delegate = delegate

    guard parser.parse() else {
      throw SeoulBusAPIError.malformedResponse(
        parser.parserError?.localizedDescription ?? "Unable to parse XML response."
      )
    }

    return SeoulBusAPIResponse(header: delegate.header, items: delegate.items)
  }

  private final class Delegate: NSObject, XMLParserDelegate {
    var header: [String: String] = [:]
    var items: [[String: String]] = []

    private var currentItem: [String: String]?
    private var currentText = ""

    func parser(
      _ parser: XMLParser,
      didStartElement elementName: String,
      namespaceURI: String?,
      qualifiedName qName: String?,
      attributes attributeDict: [String: String] = [:]
    ) {
      currentText = ""
      if elementName == "itemList" {
        currentItem = [:]
      }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
      currentText += string
    }

    func parser(
      _ parser: XMLParser,
      didEndElement elementName: String,
      namespaceURI: String?,
      qualifiedName qName: String?
    ) {
      let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

      if elementName == "itemList" {
        if let currentItem, !currentItem.isEmpty {
          items.append(currentItem)
        }
        currentItem = nil
      } else if currentItem != nil {
        currentItem?[elementName] = value
      } else if !value.isEmpty {
        header[elementName] = value
      }

      currentText = ""
    }
  }
}
