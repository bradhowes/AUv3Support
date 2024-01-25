#pragma once

#import <libkern/OSAtomic.h>
#import <atomic>
#import <cmath>

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

struct Transformers {
  static AUValue passthru(AUValue value) noexcept { return value; }

  static AUValue percentageIn(AUValue value) noexcept { return std::clamp(value / 100.0, 0.0, 1.0); }
  static AUValue percentageOut(AUValue value) noexcept { return value * 100.0; }

  static AUValue boolIn(AUValue value) noexcept { return value ? 1.0 : 0.0; }
  static AUValue boolOut(AUValue value) noexcept { return value ? 1.0 : 0.0; }

  static AUValue rounded(AUValue value) { return std::round(value); }
};
/**
 Manages a parameter value that can transition from one value to another over some number of frames.
 */
class BaseRampingParameter {
public:
  using ValueTransformer = AUValue (*)(AUValue);

  ~BaseRampingParameter() = default;

  /**
   Cancel any active ramping.
   */
  void stopRamping() noexcept {
    rampRemaining_ = 0;
  }

  /**
   Set a new value that comes from outside render thread. In order not to cause any disrutpions to active
   render operations, we delay using the new value until the next render phase.

   @param value the new value to use
   */
  void setUnsafe(AUValue target) noexcept {
    pendingValue_ = transformIn(target);
    std::atomic_fetch_add(&changeCounter_, 1);
  }

  /**
   Obtain the last value set in an unsafe (UI) way.
   @returns last unsafe value set
   */
  AUValue getUnsafe() const noexcept { return transformOut(pendingValue_); }

  /**
   Set a new value that comes from the render thread.

   @param value the new value to use
   @param duration the number of frames to transition over
   */
  void setSafe(AUValue target, AUAudioFrameCount duration) noexcept {
    valueCounter_ = changeCounter_;
    pendingValue_ = transformIn(target);
    startRamp(duration);
  }

  /**
   Obtain the current parameter value. Note that if ramping is in effect, this returns the final value at the end of
   ramping. One must use `frameValue` to obtain a ramping value.

   @return the current parameter value
   */
  AUValue getSafe() const noexcept { return value_; }

  /**
   Check if there is a new value to ramp to from the AUParameterTree.

   @param duration the number of frames to transition over
   */
  bool checkForChange(AUAudioFrameCount duration) noexcept {
    uint32_t changeCounterValue = changeCounter_;
    if (changeCounterValue == valueCounter_) return false;
    valueCounter_ = changeCounterValue;
    startRamp(duration);
    return true;
  }

  /**
   Fetch the current value, incrementing the internal value if ramping is in effect. NOTE: unlike `get` this is not an
   idempotent operation if ramping is in effect. Thus, during rendering, one must cache this value if multiple channels
   will be processed for the same frame or make sure to call with `false` value to keep from advancing to the next
   value.

   @param advance if true (default), update the underlying value when ramping; otherwise, keep as-is.
   @return the current parameter value
   */
  AUValue frameValue(bool advance = true) noexcept {
    AUAudioFrameCount adjustment = (advance && rampRemaining_) ? -1 : 0;
    auto value = rampValue(adjustment);
    rampRemaining_ += adjustment;
    return value;
  }

protected:
  
  /**
   Construct a new parameter.

   @param value the starting value for the parameter
   */
  BaseRampingParameter(AUValue value, ValueTransformer forward, ValueTransformer reverse) noexcept :
  value_{forward(value)}, pendingValue_{value_}, forwardTransform_{forward}, reverseTransform_{reverse} {}

private:

  AUValue transformIn(AUValue value) const noexcept { return forwardTransform_ ? forwardTransform_(value) : value; }
  AUValue transformOut(AUValue value) const noexcept { return reverseTransform_ ? reverseTransform_(value) : value; }

  AUValue rampValue(AUAudioFrameCount adjustment) noexcept { return rampRemaining_ ? ((rampRemaining_ + adjustment) * rampRate_ + value_) : value_; }

  void startRamp(AUAudioFrameCount duration) noexcept {
    if (duration) {
      rampRate_ = (frameValue(false) - pendingValue_) / AUValue(duration);
    }
    value_ = pendingValue_;
    rampRemaining_ = duration;
  }

  /// The value of the parameter, regardless of any ramping that may be taking place
  AUValue value_;
  AUValue rampRate_{};
  AUAudioFrameCount rampRemaining_{};

  AUValue pendingValue_;
  std::atomic<uint32_t> changeCounter_{0};
  uint32_t valueCounter_ = 0;

  ValueTransformer forwardTransform_{nullptr};
  ValueTransformer reverseTransform_{nullptr};
};

} // end namespace DSPHeaders::Parameters
