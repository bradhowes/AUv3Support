#pragma once

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Manages a parameter value that can transition from one value to another over some number of frames.
 */
template <typename T>
struct RampingParameter {
  RampingParameter() = default;
  explicit RampingParameter(AUValue initialValue) : value_{initialValue} {}
  ~RampingParameter() = default;

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the ultimate value to use for the parameter
   @param duration the number of frames to transition over
   */
  void set(T target, AUAudioFrameCount duration) {
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
  T get() const { return rampRemaining_ > 0 ? rampTarget_ : value_; }

  /**
   Fetch the current value, incrementing the internal value if ramping is in effect. NOTE: unlike `get` this is not an
   idempotent operation if ramping is in effect. Thus, during rendering, one must cache this value if multiple channels
   will be processed for the same frame.

   @return the current parameter value
   */
  T frameValue() {
    if (rampRemaining_ > 0) {
      value_ = (--rampRemaining_ == 0) ? rampTarget_ : (value_ + rampStep_);
    }
    return value_;
  }

  /**
   Obtain the current internal parameter value. This is the same as `get` but it will not be transformed into an
   external representation.

   @return the current internal parameter value
   */
  T internal() const { return get(); }

private:
  T value_;
  T rampTarget_;
  T rampStep_;
  AUAudioFrameCount rampRemaining_{0};

  RampingParameter(const RampingParameter&) = delete;
  RampingParameter(RampingParameter&&) = delete;
  RampingParameter& operator =(const RampingParameter&) = delete;
  RampingParameter& operator =(const RampingParameter&&) = delete;
};

} // end namespace DSPHeaders::Parameters
