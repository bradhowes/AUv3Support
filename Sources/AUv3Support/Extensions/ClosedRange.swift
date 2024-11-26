// Copyright © 2022-2024 Brad Howes. All rights reserved.

public extension ClosedRange where Bound : BinaryFloatingPoint {

  /// Obtain the difference between the upper bound and lower bound
  var distance: Bound { upperBound - lowerBound }

  /// Obtain the value that lies between the bounds of the range.
  var mid: Bound { distance / 2.0 + lowerBound }
}
