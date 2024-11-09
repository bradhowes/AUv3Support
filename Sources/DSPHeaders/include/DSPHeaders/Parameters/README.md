#  Parameter Classes

Various C++ classes for working with kernel parameters that can be modified at runtime.

* `Base` -- the base class for all parameter types. Supports ramping of values and safely isolates changes made by UI
so that they do not disrupt a render thread.
* `Bool` -- represents a boolean parameter (does not ramp)
* `Float` -- represents a floating-point value of size `AUValue`. Supports ramping.
* `Integral` -- represents whole numbers using floating-point values via rounding. Does not support ramping.
* `Milliseconds` -- represents a time in milliseconds. No conversion here; 
the class only exists to signal the purpose of the value via its class name.
* `Percentage` -- represents a percentage. Internally it holds a value in
[0-1] range, but externally it shows values in [0-100] range.
* `Transformer` -- collection of functions that transform `AUValue` values from one domain into another. Used by the 
other classes to define their internal values.
