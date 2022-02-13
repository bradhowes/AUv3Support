// Copyright © 2022 Brad Howes. All rights reserved.


extension ClosedRange where Bound : BinaryFloatingPoint {

  /// Obtain the difference between the upper bound and lower bound
  public var span: Bound { upperBound - lowerBound }

  /// Obtain the value that lies between the bounds of the range.
  public var mid: Bound { (upperBound - lowerBound) / 2.0 + lowerBound }
}
