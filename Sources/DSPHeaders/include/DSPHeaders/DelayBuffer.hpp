// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <vector>

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

  /**
   Construct new buffer that can hold given number of samples.

   @param sizeInSamples capacity of the buffer
   */
  DelayBuffer(double sizeInSamples) noexcept
  : buffer_(smallestPowerOf2For(sizeInSamples), 0.0), writePos_{0}, wrapMask_{buffer_.size() - 1} {}

  /**
   Wipe the buffer contents by filling it with zeros.
   */
  void clear() noexcept { std::fill(buffer_.begin(), buffer_.end(), 0.0); }

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
  T readFromOffset(int offset) const noexcept { return buffer_[(writePos_ - 1 - offset) & wrapMask_]; }

  /**
   Obtain a sample from the buffer.

   @param delay distance from the current write position to return
   @return interpolated sample from buffer
   */
  T read(T delay) const noexcept {
    auto offset = int(delay);
    T y1 = readFromOffset(offset);
    T y2 = readFromOffset(offset + 1);
    T partial = delay - offset;
    assert(partial >= 0.0 && partial < 1.0);
    return y2 * partial + (1.0 - partial) * y1;
  }

private:

  static size_t smallestPowerOf2For(double value) noexcept {
    return size_t(std::pow(2.0, std::ceil(std::log2(std::fmax(value, 1.0)))));
  }

  std::vector<T> buffer_;
  size_t writePos_;
  size_t wrapMask_;
};

} // end namespace DSPHeaders
