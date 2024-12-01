// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterTree {

  /**
   Access parameter in tree via ParameterAddressProvider (eg enum).

   - parameter address: the address to fetch
   - returns: the found value
   */
  @inlinable
  func parameter(source: ParameterAddressProvider) -> AUParameter? {
    parameter(withAddress: source.parameterAddress)
  }
}

extension AUParameterTree {

  /// Provide pseudo-@dynamicMemberLookup functionality to AUParameterTree
  public var dynamicMemberLookup: AUParameterNodeDML { .group(self) }
}

@dynamicMemberLookup
public enum AUParameterNodeDML {
  case group(AUParameterGroup)
  case param(AUParameter)

  public var group: AUParameterGroup? {
    if case .group(let group) = self { return group }
    return nil
  }

  public var parameter: AUParameter? {
    if case .param(let param) = self { return param }
    return nil
  }

  public subscript(dynamicMember identifier: String) -> AUParameterNodeDML? {
    guard case .group(let group) = self else { return nil }
    for each in group.children where each.identifier == identifier {
      switch each {
      case let group as AUParameterGroup: return .group(group)
      case let param as AUParameter: return .param(param)
      default: return nil // can never happen
      }
    }
    return nil
  }
}

