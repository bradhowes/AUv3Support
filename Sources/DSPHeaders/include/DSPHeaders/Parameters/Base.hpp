// Copyright © 2022-2025 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <atomic>
#import <cassert>

#import <AVFoundation/AVFoundation.h>
#import "DSPHeaders/Concepts.hpp"
#import "DSPHeaders/Parameters/Transformer.hpp"
#import "DSPHeaders/Types.hpp"

namespace DSPHeaders::Parameters {

/**
 Base class that manages a parameter value that can transition from one value to another over some number of frames.
 It does so in a thread-safe manner so that changes coming from AUParameterTree notifications (presumably from UI
 activity) does not modify state that may be in use in a rendering thread.

 A parameter can have an internal representation that differs from an external (UI) one. The parameter holds two
 attributes, `transformIn_` and `transformOut_`, that perform the conversion from external representation to internal
 one (`transformIn`) and the opposite (`transformOut`) for making an external value from the internal representation.
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
  void stopRamping() noexcept {
    if (rampRemaining_ > 0) {
      rampRemaining_ = 0;
      value_ = pendingValue_.load(std::memory_order_relaxed);
    }
  }

  /// @returns true if ramping is in effect
  bool isRamping() const noexcept { return rampRemaining_ > 0; }

  /**
   Set a new value that comes from outside render thread. It will be seen at the start of the next
   render pass.

   @param value the new value to use
   */
  void setPending(AUValue value) noexcept {
    pendingValue_.store(transformIn_(value), std::memory_order_relaxed);
    // Stop any active ramping to allow a new ramp to begin.
    rampRemaining_ = 0;
  }

  /**
   Obtain the last value set via `setPending`.

   @returns last pending value set
   */
  AUValue getPending() const noexcept { return transformOut_(pendingValue_.load(std::memory_order_relaxed)); }

  /**
   Set a new value that comes from the render thread via `AURenderEventParameter` or `AURenderEventParameterRamp`.
   Since we are in the render thread, we can safely set the ramping now.

   @param value the new value to use
   @param duration the number of frames to transition over
   */
  void setImmediate(AUValue value, AUAudioFrameCount duration) noexcept {
    value = transformIn_(value);
    pendingValue_.store(value, std::memory_order_relaxed);
    startRamp(value, duration);
  }

  /**
   Obtain the last value set via `setImmediate`. Note that this is the same as `getPending`.

   @return the last pending value set
   */
  AUValue getImmediate() const noexcept { return transformOut_(pendingValue_.load(std::memory_order_relaxed)); }

  /**
   Check if there is a new value to ramp to that was set via `setPending`.

   @param duration the number of frames to transition over
   */
  bool checkForValueChange(AUAudioFrameCount duration) noexcept {
    auto pending = pendingValue_.load(std::memory_order_relaxed);

    // Nothing changed.
    if (pending == value_) [[likely]] {
      return false;
    }

    // Ramping already in-progress
    if (rampRemaining_ > 0) [[unlikely]] {
      value_ = --rampRemaining_ > 0 ? (value_ + rampDelta_) : pending;
      return false;
    }

    startRamp(pending, duration);
    return rampRemaining_ > 0;
  }

  /**
   Fetch the current -- possibly ramping -- value.

   @return the current parameter value
   */
  AUValue frameValue() const noexcept { return value_; }

protected:

  /**
   Construct a new parameter.

   @param address the AUParameterAddress for the parameter
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   @param forward a transformation to apply to incoming values before storing in the parameter
   @param reverse a transformation to apply to a held value before it is returned to a caller
   */
  Base(AUParameterAddress address, AUValue value, bool canRamp, ValueTransformer forward,
       ValueTransformer reverse) noexcept :
  address_{address}, value_{forward(value)}, transformIn_{forward}, transformOut_{reverse}, canRamp_{canRamp} {
    assert(transformIn_ && transformOut_);
    pendingValue_.store(value_, std::memory_order_relaxed);
  }

private:

  void startRamp(AUValue pendingValue, AUAudioFrameCount duration) noexcept {
    if (canRamp_ && duration > 1) {
      rampDelta_ = (pendingValue - value_) / AUValue(duration);
    } else {
      duration = 1;
      rampDelta_ = pendingValue - value_;
    }
    rampRemaining_ = duration - 1;
    value_ += rampDelta_;
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

  /// Holds `true` if the parameter supports ramping. Boolean values do not, for instance.
  bool canRamp_;
};

} // end namespace DSPHeaders::Parameters
