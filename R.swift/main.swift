//
//  main.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 11-12-14.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

let IndentationString = "  "

let ResourceFilename = "R.generated.swift"

private let Header = [
  "// This is a generated file, do not edit!",
  "// Generated by R.swift, see https://github.com/mac-cain13/R.swift",
  ].joined(separator: "\n")

do {
  let callInformation = try CallInformation(processInfo: ProcessInfo())

  let xcodeproj = try Xcodeproj(url: callInformation.xcodeprojURL)
  let resourceURLs = try xcodeproj.resourcePathsForTarget(callInformation.targetName)
    .map(pathResolver(with: callInformation.URLForSourceTreeFolder))
    .flatMap { $0 }

  let resources = Resources(resourceURLs: resourceURLs, fileManager: FileManager.default)

  let resourceStruct = generateResourceStructs(with: resources, at: callInformation.accessLevel, forBundleIdentifier: callInformation.bundleIdentifier)

  let usedModules = resourceStruct.usedTypes
    .map { $0.type.module }

  let imports = Set(usedModules)
    .subtracting([Module.custom(name: callInformation.productModuleName), Module.host, Module.stdLib])
    .sortBy { $0.description }
    .map { "import \($0)" }
    .joined(separator: "\n")

  let fileContents = [
      Header,
      imports,
      resourceStruct.swiftCode
    ].joined(separator: "\n\n")

  // Write file if we have changes
  let currentFileContents = try? String(contentsOf: callInformation.outputURL, encoding: String.Encoding.utf8)
  if currentFileContents != fileContents  {
    do {
      try fileContents.write(to: callInformation.outputURL, atomically: true, encoding: String.Encoding.utf8)
    } catch let error as NSError {
      fail(error.description)
    }
  }

} catch let error as InputParsingError {
  if let errorDescription = error.errorDescription {
    fail(errorDescription)
  }

  print(error.helpString)

  switch error {
  case .illegalOption, .missingOption:
    exit(2)
  case .userAskedForHelp, .userRequestsVersionInformation:
    exit(0)
  }
} catch let error as ResourceParsingError {
  switch error {
  case let .parsingFailed(description):
    fail(description)
  case let .unsupportedExtension(givenExtension, supportedExtensions):
    let joinedSupportedExtensions = supportedExtensions.joined(separator: ", ")
    fail("File extension '\(givenExtension)' is not one of the supported extensions: \(joinedSupportedExtensions)")
  }

  exit(3)
}
