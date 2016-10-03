//
//  Let.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 05-01-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import Foundation

enum TypeDefinition: UsedTypesProvider {
  case specified(Type)
  case inferred(Type?)

  var type: Type? {
    switch self {
    case let .specified(type): return type
    case let .inferred(type): return type
    }
  }

  var usedTypes: [UsedType] {
    return type?.usedTypes ?? []
  }
}

struct Let: UsedTypesProvider, SwiftCodeConverible {
  let comments: [String]
  let accessModifier: AccessModifier
  let isStatic: Bool
  let name: SwiftIdentifier
  let typeDefinition: TypeDefinition
  let value: String

  init(comments: [String], accessModifier: AccessModifier, isStatic: Bool, name: SwiftIdentifier, typeDefinition: TypeDefinition, value: String) {
    self.comments = comments
    self.accessModifier = accessModifier
    self.isStatic = isStatic
    self.name = name
    self.typeDefinition = typeDefinition
    self.value = value
  }

  var usedTypes: [UsedType] {
    return typeDefinition.usedTypes
  }

  var swiftCode: String {
    let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
    let accessModifierString = (accessModifier == .Internal) ? "" : accessModifier.rawValue + " "
    let staticString = isStatic ? "static " : ""

    let typeString: String
    switch typeDefinition {
    case let .specified(type): typeString = ": \(type)"
    case .inferred: typeString = ""
    }

    return "\(commentsString)\(accessModifierString)\(staticString)let \(name)\(typeString) = \(value)"
  }
}
