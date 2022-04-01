import AudioToolbox

/**
 Representation of a value between 0 and 1 that can be easily converted into other forms. Instances are immutable.
 */
public struct ParametricValue: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = AUValue

  public let value: AUValue

  @inlinable
  public init(_ aValue: AUValue) {
    self.value = aValue.clamped(to: 0...1)
  }

  @inlinable
  public init(floatLiteral aValue: AUValue) {
    self.init(aValue)
  }

  var exponential: Self { .init((powf(10, value) - 1) / 9.0) }
  var logarithmic: Self { .init(log10f(10 * value + 1) / log10f(11)) }
  var squared: Self { .init(value * value) }
  var squareRoot: Self { .init(sqrtf(value)) }
  var cubed: Self { .init(value * value * value) }
  var cubeRoot: Self { .init(cbrtf(value)) }
}
