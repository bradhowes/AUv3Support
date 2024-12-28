# DSPHeaders

This package contains various C++ classes that are useful when rendering audio samples for an AUv3 audio unit.

* `Biquad` -- collection of routines used to create bi-quad filters in different configurations
* `BusBufferFacet` --  provides a simple `std::vector` view of an `AudioBufferList` where each entry in the vector is a
pointer to a stream of `AUValue` values for a given bus channel.
* `BusBuffers` -- collection of buffers per bus entity
* `ConstMath` -- collection of routines that perform compile-time math operations
* `DelayBuffer` -- a circular-buffer that holds past audio samples that can be retrieved at a time offset
* `DSP` -- small collection of signal processing functions, mostly having to do with manipulating LFO values
* `EventProcessor` -- an AUv3 sample rendering processor that serves as the basis for AUv3 filters. This is a template
class that takes a 'kernel' type which defines the actual operations to perform within an AUv3 context.
* `LFO` -- low-frequency oscillator class with parameters to control rate and waveform type
* `PhaseShifter` -- an all-pass filter that performs phase shifting across a predefined set of frequencies.
* `BusSampleBuffer` -- set of N-channel fixed-sized sample buffers. Light-weight wrapper around the `AVAudioPCMBuffer`
 class.

Originally, this was a C++ headers-only package, but now there is a `DSPHeaders.mm` file that contains various lookup
table generators that are run at compile time to fill the coefficient lookup tables used by the cubic 4-order
interpolation routine (4 value generators for the 4 coefficients).

# Usage

Add `.product(name: "AUv3-DSP-Headers", package: "AUv3Support", condition: .none)` to the list of
dependencies in your C++ target and then `#include` whatever header you want. Note that adding the dependency will
affect the search path used for finding include files, so you just need to use the file name without any path component.
