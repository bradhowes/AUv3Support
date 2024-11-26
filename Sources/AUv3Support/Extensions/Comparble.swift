// Copyright © 2022-2024 Brad Howes. All rights reserved.

public extension Comparable {
  
  /**
   Make sure that a value falls within a given range, forcing it to be at either extreme if it is outside of the
   range.
   
   - parameter range: the limits to check against
   - returns clamped value
   */
  @inlinable
  func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}
