// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <atomic>
#import <cassert>

#import <AVFoundation/AVFoundation.h>
#import "DSPHeaders/Parameters/Transformer.hpp"

namespace DSPHeaders::Parameters {

/**
 Base class that manages a parameter value that can transition from one value to another over some number of frames.
 It does so in a thread-safe manner so that changes coming from AUParameterTree notifications (presumably from UI
 activity) does not modify state that may be in use in a rendering thread.
 */
class Base {
public:
  using ValueTransformer = AUValue (*)(AUValue);

  AUParameterAddress address() const noexcept { return address_; }

  bool canRamp() const noexcept { return canRamp_; }

  /**
   Cancel any active ramping.

   Note: this should only be invoked when the render thread is not running.
   */
  void stopRamping() noexcept { rampRemaining_ = 0; }

  /// @returns true if ramping is in effect
  bool isRamping() const noexcept { return rampRemaining_ > 0; }

  /**
   Set a new value that comes from outside render thread. It will be seen at the start of the next
   render pass.

   @param value the new value to use
   */
  void setPending(AUValue value) noexcept {
    pendingValue_.store(transformIn_(value), std::memory_order_relaxed);
  }

  /**
   Obtain the last value set via `setPending`.

   @returns last unsafe value set
   */
  AUValue getPending() const noexcept { return transformOut_(pendingValue_.load(std::memory_order_relaxed)); }

  /**
   Set a new value that comes from the render thread via `AURenderEventParameter` or `AURenderEventParameterRamp`.

   @param value the new value to use
   @param duration the number of frames to transition over
   */
  void setImmediate(AUValue value, AUAudioFrameCount duration) noexcept {
    value = transformIn_(value);
    startRamp(value, duration);
    pendingValue_.store(value, std::memory_order_relaxed);
  }

  /**
   Obtain the current parameter value. Note that if ramping is in effect, this returns the final value at the end of
   ramping. One must use `frameValue` to obtain the ramped value.

   @return the current parameter value
   */
  AUValue getImmediate() const noexcept { return transformOut_(value_); }

  /**
   Check if there is a new value to ramp to from the AUParameterTree.

   @param duration the number of frames to transition over
   */
  bool checkForPendingChange(AUAudioFrameCount duration) noexcept {
    auto pending = pendingValue_.load(std::memory_order_relaxed);
    if (pending == value_) [[likely]] {
      return false;
    }
    startRamp(pending, duration);
    return canRamp_;
  }

  /**
   Fetch the current value, incrementing the internal value if ramping is in effect. NOTE: unlike `get` this is not an
   idempotent operation if ramping is in effect. Thus, during rendering, one must cache this value if multiple channels
   will be processed for the same frame or make sure to call with `false` value to keep from advancing to the next
   value.

   Should only be called from the rendering thread.

   @param advance if true (default), update the underlying value when ramping; otherwise, keep as-is.
   @return the current parameter value
   */
  AUValue frameValue(bool advance = true) noexcept {
    auto remaining = rampRemaining_ - AUAudioFrameCount((advance && rampRemaining_) ? 1 : 0);
    auto value = remaining * rampDelta_ + value_;
    rampRemaining_ = remaining;
    return value;
  }

  /// @return the parameter value after any ramping that might be in effect (render thread)
  AUValue finalValue() const noexcept { return value_; }

protected:

  /**
   Construct a new parameter.

   @param value the starting value for the parameter
   */
  Base(AUParameterAddress address, AUValue value, bool canRamp, ValueTransformer forward,
       ValueTransformer reverse) noexcept :
  address_{address}, value_{forward(value)}, transformIn_{forward}, transformOut_{reverse}, canRamp_{canRamp} {
    assert(transformIn_ && transformOut_);
    pendingValue_.store(value_, std::memory_order_relaxed);
  }

private:

  void startRamp(AUValue pendingValue, AUAudioFrameCount duration) noexcept {
    if (canRamp_ && duration) {
      rampDelta_ = (frameValue(false) - pendingValue) / AUValue(duration);
    }
    rampRemaining_ = duration;
    value_ = pendingValue;
  }

  /// The address of the parameter.
  AUParameterAddress address_;

  /// The value of the parameter, regardless of any ramping that may be taking place. This should only be manipulated
  /// by the rendering thread or when there is no rendering being done.
  AUValue value_;

  /// The change to apply to the parameter at each frame while ramping. This should only be manipulated
  /// by the rendering thread or when there is no rendering being done.
  AUValue rampDelta_{0.0};

  /// The number of frames left while ramping the parameter to a new value. This should only be manipulated by the
  /// rendering thread or when there is no rendering being done.
  AUAudioFrameCount rampRemaining_{0};

  /// The value to apply in the next render pass.
  std::atomic<AUValue> pendingValue_;

  /// How to transform external values to internal representation used by the kernel.
  ValueTransformer transformIn_;

  /// How to transform kernel values to external representation.
  ValueTransformer transformOut_;

  bool canRamp_;
};

} // end namespace DSPHeaders::Parameters
