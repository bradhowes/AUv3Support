#pragma once

#import <libkern/OSAtomic.h>
#import <atomic>
#import <cmath>

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

struct Transformers {

  /**
   A no-op transformer

   @param value the value to transform
   @returns transformed value
   */
  static AUValue passthru(AUValue value) noexcept { return value; }

  /**
   A transformer of percentage values (0-100) into a normalized one (0.0-1.0)

   @param value the value to transform
   @returns transformed value
   */
  static AUValue percentageIn(AUValue value) noexcept { return std::clamp(value / 100.0, 0.0, 1.0); }

  /**
   A transformer of normalized values (0.0-1.0) into percentages (0-100)

   @param value the value to transform
   @returns transformed value
   */
  static AUValue percentageOut(AUValue value) noexcept { return value * 100.0; }

  /**
   A transformer of floating-point values into a boolean, where 0.0 means false and anything else 1.0.

   @param value the value to transform
   @returns transformed value
   */
  static AUValue boolIn(AUValue value) noexcept { return value ? 1.0 : 0.0; }

  /**
   A transformer of floating-point values into integral ones.

   @param value the value to transform
   @returns transformed value
   */
  static AUValue rounded(AUValue value) { return std::round(value); }
};

/**
 Base class that manages a parameter value that can transition from one value to another over some number of frames.
 It does so in a thread-safe manner so that changes coming from AUParameterTree notifications (presumably from UI
 activity) does not modify state that may be in use in a rendering thread.
 */
class BaseRampingParameter {
public:
  using ValueTransformer = AUValue (*)(AUValue);

  ~BaseRampingParameter() noexcept = default;

  /**
   Cancel any active ramping.
   */
  void stopRamping() noexcept { rampRemaining_ = 0; }

  /**
   Set a new value that comes from outside render thread. In order not to cause any disrutpions to active
   render operations, we delay using the new value until the next render phase.

   @param value the new value to use
   */
  void setUnsafe(AUValue target) noexcept {

    // Spin until render thread has taken the last value
    while (changeCounter_.load(std::memory_order_relaxed) > 0U)
      ;

    // Safe to set this value
    pendingValue_ = transformIn(target);

    // Signal a new value
    std::atomic_fetch_add(&changeCounter_, 1);
  }

  /**
   Obtain the last value set in an unsafe (UI) way.

   @returns last unsafe value set
   */
  AUValue getUnsafe() const noexcept { return transformOut(pendingValue_); }

  /**
   Set a new value that comes from the render thread. Note that technically this is unsafe from the standpoint of
   any UI that may be asking for the parameter's value at the same time, which is a very rare chance of happening
   since the UI would normally not need to query for the value to show.

   @param value the new value to use
   @param duration the number of frames to transition over
   */
  void setSafe(AUValue target, AUAudioFrameCount duration) noexcept {
    auto value = transformIn(target);
    pendingValue_ = value;
    startRamp(value, duration);
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

    // See if UI has set value
    if (changeCounter_.load(std::memory_order_relaxed) == 0U) return false;

    // Safe to grab the new value
    auto value = pendingValue_;

    // Now clear the sentinal
    std::atomic_fetch_add(&changeCounter_, -1);

    startRamp(value, duration);
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
  value_{forward(value)}, pendingValue_{value_}, forwardTransform_{forward}, reverseTransform_{reverse} {
    assert(forwardTransform_ && reverseTransform_);
  }

private:

  AUValue transformIn(AUValue value) const noexcept { return forwardTransform_(value); }

  AUValue transformOut(AUValue value) const noexcept { return reverseTransform_(value); }

  AUValue rampValue(AUAudioFrameCount adjustment) noexcept { return rampRemaining_ ? ((rampRemaining_ + adjustment) * rampRate_ + value_) : value_; }

  void startRamp(AUValue pendingValue, AUAudioFrameCount duration) noexcept {
    if (duration) rampRate_ = (frameValue(false) - pendingValue) / AUValue(duration);
    value_ = pendingValue;
    rampRemaining_ = duration;
  }

  /// The value of the parameter, regardless of any ramping that may be taking place
  AUValue value_;
  AUValue rampRate_{};
  AUAudioFrameCount rampRemaining_{};

  AUValue pendingValue_;
  std::atomic<uint32_t> changeCounter_{0};

  ValueTransformer forwardTransform_{nullptr};
  ValueTransformer reverseTransform_{nullptr};
};

} // end namespace DSPHeaders::Parameters
