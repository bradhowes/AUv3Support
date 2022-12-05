# DSPHeaders

This package contains various C++ classes that are very useful when rendering audio samples for an AUv3 audio unit.

* `BoolParameter` -- represents an `AUParameter` whose `AUValue` will be converted into true/false values.
* `BufferFacet` --  provides a simple `std::vector` view of an `AudioBufferList` where each entry in the vector is a
pointer to a stream of `AUValue` values for a given channel.
* `DelayBuffer` -- a circular-buffer that holds past audio samples that can be retrieved at a time offset
* `DSP` -- small collection of signal processing functions, mostly having to do with manipulating LFO values
* `MillisecondsParameter` -- represents an `AUParameter` whose `AUValue` is time in milliseconds. No conversion here;
the class only exists to signal the purpose of the value via its class name.
* `PercentageParameter` -- represents an `AUParameter` whose `AUValue` is a percentage. Internally it holds a value in
[0-1] range.
* `RampingParameter` -- supports changing an `AUParameter` value over N samples. Both `MillisecondsParameter`
and `PercentageParameter` are based on this class, and `LFO` uses it to ramp changes to its oscillating frequency.

Originally, this was a C++ headers-only package, but now there is a `DSPHeaders.mm` file that contains various lookup
table generators that are run at compile time to fill the coefficient lookup tables used by the cubic 4-order 
interpolation routine (4 value generators for the 4 coefficients).

# Usage

Add `.productItem(name: "AUv3-DSP-Headers", package: "AUv3SupportPackage", condition: .none)` to the list of 
dependencies in your C++ target and then `#include` whatever header you want. Note that adding the dependency will
affect the search path used for finding include files, so you just need to use the file name without any path component.
