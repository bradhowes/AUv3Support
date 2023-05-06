#pragma once

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Manages a parameter value that can transition from one value to another over some number of frames.
 */
template <typename ValueType = AUValue>
class RampingParameter {
public:

  /**
   Construct a new parameter.

   @param initialValue the starting value for the parameter
   */
  explicit RampingParameter(ValueType initialValue) noexcept : value_{initialValue}, rampedValue_{initialValue} {}

  RampingParameter() = default;

  ~RampingParameter() = default;

  /**
   Cancel any active ramping.
   */
  void stopRamping() noexcept {
    if (rampRemaining_ > 0) {
      rampRemaining_ = 0;
      rampedValue_ = value_;
    }
  }

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the ultimate value to use for the parameter
   @param duration the number of frames to transition over
   */
  void set(ValueType target, AUAudioFrameCount duration = 0) noexcept {
    if (duration > 0) {
      rampRemaining_ = duration;
      rampStep_ = (target - rampedValue_) / AUValue(duration);
      value_ = target;
    } else {
      value_ = target;
      rampedValue_ = target;
      rampRemaining_ = 0;
    }
  }

  /**
   Obtain the current parameter value. Note that if ramping is in effect, this returns the final value at the end of
   ramping. One must use `frameValue` to obtain a ramping value.

   @return the current parameter value
   */
  ValueType get() const noexcept { return value_; }

  /**
   Fetch the current value, incrementing the internal value if ramping is in effect. NOTE: unlike `get` this is not an
   idempotent operation if ramping is in effect. Thus, during rendering, one must cache this value if multiple channels
   will be processed for the same frame or make sure to call with `false` value to keep from advancing to the next
   value.

   @param advance if true (default), update the underlying value when ramping; otherwise, keep as-is.
   @return the current parameter value
   */
  ValueType frameValue(bool advance = true) noexcept {
    if (advance && rampRemaining_ > 0) {
      rampedValue_ = (--rampRemaining_ == 0) ? value_ : (rampedValue_ + rampStep_);
    }
    return rampedValue_;
  }

private:
  /// The value of the parameter, regardless of any ramping that may be taking place
  ValueType value_;
  /// The "ramped" value which will become `value_` after `rampRemaining_` frames.
  ValueType rampedValue_;
  /// The change that takes place in `rampedValue_` after a frame.
  ValueType rampStep_{0.0};
  /// The number of frames remaining in a ramp.
  AUAudioFrameCount rampRemaining_{0};
};

} // end namespace DSPHeaders::Parameters
