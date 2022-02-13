// Copyright © 2022 Brad Howes. All rights reserved.

public extension ClosedRange where Bound: BinaryFloatingPoint {

  /// Obtain the difference between the upper bound and lower bound
  var span: Bound { upperBound - lowerBound }

  /// Obtain the value that lies between the bounds of the range.
  var mid: Bound { span / 2.0 + lowerBound }
}
