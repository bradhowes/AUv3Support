// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <vector>

#import "DSPHeaders/DSP.hpp"

namespace DSPHeaders {

/**
 Delay buffer that holds a maximum number of samples. It manages a write position which is where new samples are added
 to the buffer. Reading takes place some samples before the current write position with linear interpolation being used
 to generate the sample value.

 This buffer is not thread-safe.
 */
template <typename T>
class DelayBuffer {
public:

  /// Types of interpolation that can be used to generate sample values using floating-point indices.
  enum struct Interpolator {
    linear,
    cubic4thOrder
  };

  /**
   Construct new buffer that can hold given number of samples.

   @param sizeInSamples capacity of the buffer
   @param kind the interpolation to apply to the samples. Default is linear.
   */
  DelayBuffer(double sizeInSamples, Interpolator kind = Interpolator::linear) noexcept :
  buffer_(smallestPowerOf2For(sizeInSamples), T{0.0}), writePos_{0}, wrapMask_{buffer_.size() - 1},
  interpolatorProc_{interpolator(kind)} {}

  /**
   Wipe the buffer contents by filling it with zeros.
   */
  void clear() noexcept { std::fill(buffer_.begin(), buffer_.end(), T{0.0}); }

  /**
   Write a sample to the end of the buffer.

   @param value the sample to add
   */
  void write(T value) noexcept {
    buffer_[writePos_] = value;
    writePos_ = (writePos_ + 1) & wrapMask_;
  }

  /**
   Physical size of the buffer. This is always a power of 2 and may not match the value given in the constructor or the
   last `setSizeInSamples` call.

   @return buffer size
   */
  size_t size() const noexcept { return buffer_.size(); }

  /**
   Obtain a sample from the buffer.

   @param offset how many samples before the current write position to return
   @return sample from buffer
   */
  T readFromOffset(ssize_t offset) const noexcept { return buffer_[size_t(writePos_ - 1 - offset) & wrapMask_]; }

  /**
   Obtain a sample from the buffer.

   @param delay distance from the current write position to return
   @return interpolated sample from buffer
   */
  T read(T delay) const noexcept {
    auto offset = int(delay);
    return (this->*interpolatorProc_)(offset, delay - offset);
  }

private:
  using InterpolatorProc = T (DelayBuffer::*)(ssize_t, T) const noexcept;

  static size_t smallestPowerOf2For(double value) noexcept {
    return size_t(std::pow(2.0, std::ceil(std::log2(std::fmax(value, 1.0)))));
  }

  static InterpolatorProc interpolator(Interpolator kind) noexcept {
    return kind == Interpolator::linear ? &DelayBuffer::linearInterpolate : &DelayBuffer::cubic4thOrderInterpolate;
  }

  T at(ssize_t offset) const noexcept { return readFromOffset(offset); }

  /**
   Obtain a linearly interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @returns interpolated sample result
   */
  T linearInterpolate(ssize_t whole, T partial) const noexcept {
    return DSP::Interpolation::linear(partial, at(whole), at(whole + 1));
  }

  /**
   Obtain a cubic 4th-order interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @returns interpolated sample result
   */
  T cubic4thOrderInterpolate(ssize_t whole, T partial) const noexcept {
    return DSP::Interpolation::cubic4thOrder(partial, at(whole - 1), at(whole), at(whole + 1), at(whole + 2));
  }

  std::vector<T> buffer_;
  size_t writePos_;
  size_t wrapMask_;
  InterpolatorProc interpolatorProc_;
};

} // end namespace DSPHeaders
