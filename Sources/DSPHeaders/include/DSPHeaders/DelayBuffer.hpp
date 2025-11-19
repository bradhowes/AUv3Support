// Copyright © 2021-2025 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <vector>

#import "DSPHeaders/DSP.hpp"

namespace DSPHeaders {

/**
 Circular buffer that holds a maximum number of samples. It manages a write position which is where new samples are
 added to the buffer. Reading takes place some samples before the current write position with interpolation
 being used to generate the sample value. This only works as long as each sample is written at a fixed sample rate so
 that a delay in seconds can be calculated as N number of samples in the past.

 This buffer is not thread-safe. It is to be used in a the rendering flow of one channel of audio.
 */
template <typename ValueType>
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
  buffer_(smallestPowerOf2For(sizeInSamples), ValueType{0.0}), writePos_{0}, wrapMask_{buffer_.size() - 1},
  interpolatorProc_{interpolator(kind)} {}

  /**
   Wipe the buffer contents by filling it with zeros.
   */
  void clear() noexcept { std::fill(buffer_.begin(), buffer_.end(), ValueType{0.0}); }

  /**
   Write a sample to the end of the buffer, advancing the write position to the next location.

   @param value the sample to add
   */
  void write(ValueType value) noexcept {
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
  ValueType readFromOffset(ssize_t offset) const noexcept {
    return buffer_[size_t(writePos_ - 1 - offset) & wrapMask_];
  }

  /**
   Obtain a sample from the buffer using interpolation method defined at construction.

   @param delay distance from the current write position to return
   @return interpolated sample from buffer
   */
  ValueType read(ValueType delay) const noexcept {
    // Convert delay distance into whole and partial components.
    auto offset = int(delay);
    return (this->*interpolatorProc_)(offset, delay - offset);
  }

private:
  using InterpolatorProc = ValueType (DelayBuffer::*)(ssize_t, ValueType) const noexcept;

  static size_t smallestPowerOf2For(double value) noexcept {
    return size_t(std::pow(2.0, std::ceil(std::log2(std::fmax(value, 1.0)))));
  }

  static InterpolatorProc interpolator(Interpolator kind) noexcept {
    return kind == Interpolator::linear ? &DelayBuffer::linearInterpolate : &DelayBuffer::cubic4thOrderInterpolate;
  }

  /**
   Obtain a linearly interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @returns interpolated sample result
   */
  ValueType linearInterpolate(ssize_t whole, ValueType partial) const noexcept {
    return (partial == 0.0) ? readFromOffset(whole) : DSP::Interpolation::linear(partial,
                                                                                 readFromOffset(whole),
                                                                                 readFromOffset(whole + 1));
  }

  /**
   Obtain a cubic 4th-order interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @returns interpolated sample result
   */
  ValueType cubic4thOrderInterpolate(ssize_t whole, ValueType partial) const noexcept {
    // I think the indexing here may be off just slightly, but at 44.1K sampling rate, I'm not that concerned.
    return (partial == 0.0) ? readFromOffset(whole) : DSP::Interpolation::cubic4thOrder(partial,
                                                                                        readFromOffset(whole),
                                                                                        readFromOffset(whole + 1),
                                                                                        readFromOffset(whole + 2),
                                                                                        readFromOffset(whole + 3));
  }

  std::vector<ValueType> buffer_;
  size_t writePos_;
  size_t wrapMask_;
  InterpolatorProc interpolatorProc_;
};

} // end namespace DSPHeaders
