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

  virtual ~Base() noexcept = default;

  /**
   Cancel any active ramping.
   */
  void stopRamping() noexcept { rampRemaining_ = 0; }

  /**
   Set a new value that comes from outside render thread. It will be seen at the start of the next
   render pass.

   @param value the new value to use
   */
  void setPending(AUValue value) noexcept { pendingValue_.store(transformIn_(value), std::memory_order_relaxed); }

  /**
   Obtain the last value set via `setPending`.

   @returns last unsafe value set
   */
  AUValue getPending() const noexcept { return transformOut_(pendingValue_.load(std::memory_order_relaxed)); }

  /**
   Set a new value that comes from the render thread.

   @param value the new value to use
   @param duration the number of frames to transition over

   @todo Need to signal the AUParameterTree that this has happened
   */
  void set(AUValue value, AUAudioFrameCount duration) noexcept {
    startRamp(transformIn_(value), duration);
    pendingValue_.store(transformIn_(value));
  }

  /**
   Obtain the current parameter value. Note that if ramping is in effect, this returns the final value at the end of
   ramping. One must use `frameValue` to obtain a ramping value.

   @return the current parameter value
   */
  AUValue get() const noexcept { return value_; }

  /**
   Check if there is a new value to ramp to from the AUParameterTree.

   @param duration the number of frames to transition over
   */
  bool checkForChange(AUAudioFrameCount duration) noexcept {
    auto value = pendingValue_.load(std::memory_order_relaxed);
    if (value == value_) [[likely]] return false;
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
    AUAudioFrameCount adjustment = (advance && rampRemaining_) ? 1 : 0;
    auto value = rampRemaining_ ? ((rampRemaining_ - adjustment) * rampRate_ + value_) : value_;
    rampRemaining_ -= adjustment;
    return value;
  }

protected:
  
  /**
   Construct a new parameter.

   @param value the starting value for the parameter
   */
  Base(AUValue value, ValueTransformer forward, ValueTransformer reverse) noexcept :
  value_{forward(value)}, transformIn_{forward}, transformOut_{reverse} {
    assert(transformIn_ && transformOut_);
    pendingValue_.store(value_, std::memory_order_relaxed);
  }

  virtual void startRamp(AUValue pendingValue, AUAudioFrameCount duration) noexcept {
    if (duration) [[likely]] rampRate_ = (frameValue(false) - pendingValue) / AUValue(duration);
    value_ = pendingValue;
    rampRemaining_ = duration;
  }

  /// The value of the parameter, regardless of any ramping that may be taking place
  AUValue value_;
  AUValue rampRate_{};
  AUAudioFrameCount rampRemaining_{};

  std::atomic<AUValue> pendingValue_{0.0};

  ValueTransformer transformIn_{nullptr};
  ValueTransformer transformOut_{nullptr};
};

} // end namespace DSPHeaders::Parameters
