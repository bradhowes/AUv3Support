// Copyright © 2022 Brad Howes. All rights reserved.

public extension ClosedRange where Bound: BinaryFloatingPoint {

  /// Obtain the value that lies between the bounds of the range.
  var mid: Bound { (upperBound - lowerBound) / 2.0 + lowerBound }
}
