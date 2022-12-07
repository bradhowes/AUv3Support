#pragma once

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Manages a parameter value that can transition from one value to another over some number of frames.
 */
template <typename T>
struct RampingParameter {

  RampingParameter() = default;

  explicit RampingParameter(T initialValue) noexcept : value_{initialValue} {}

  ~RampingParameter() = default;

  /// @returns true if ramping is in effect
  bool isRamping() const noexcept { return rampRemaining_ > 0; }

  /**
   Cancel any active ramping.
   */
  void stopRamping() noexcept {
    if (rampRemaining_ > 0) {
      rampRemaining_ = 0;
      value_ = rampTarget_;
    }
  }

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the ultimate value to use for the parameter
   @param duration the number of frames to transition over
   */
  void set(T target, AUAudioFrameCount duration) noexcept {
    if (duration > 0) {
      rampRemaining_ = duration;
      rampTarget_ = target;
      rampStep_ = (rampTarget_ - value_) / T(duration);
    } else {
      value_ = target;
      rampRemaining_ = 0;
    }
  }

  /**
   Obtain the current parameter value. Note that if ramping is in effect, this returns the final value at the end of
   ramping. One must use `frameValue` to obtain the value during ramping.

   @return the current parameter value
   */
  T get() const noexcept { return rampRemaining_ > 0 ? rampTarget_ : value_; }

  /**
   Fetch the current value, incrementing the internal value if ramping is in effect. NOTE: unlike `get` this is not an
   idempotent operation if ramping is in effect. Thus, during rendering, one must cache this value if multiple channels
   will be processed for the same frame.

   @return the current parameter value
   */
  T frameValue() noexcept {
    if (rampRemaining_ > 0) {
      value_ = (--rampRemaining_ == 0) ? rampTarget_ : (value_ + rampStep_);
    }
    return value_;
  }

private:
  T value_;
  T rampTarget_;
  T rampStep_;
  AUAudioFrameCount rampRemaining_{0};
};

} // end namespace DSPHeaders::Parameters
