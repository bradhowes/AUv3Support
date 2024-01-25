// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "RampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Holds a boolean value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
template <typename ValueType = AUValue>
class BoolParameter : private RampingParameter<ValueType> {
public:
  using super = RampingParameter<ValueType>;

  /**
   Construct new instance from POD value.

   @param init the value to hold
   */
  explicit BoolParameter(bool init) noexcept : super(init ? 1.0 : 0.0) {}

  BoolParameter() = default;

  ~BoolParameter() = default;

  void setUnsafe(bool value) noexcept { super::setUnsafe(value ? 1.0 : 0.0); }

  ValueType getUnsafe() const noexcept { return super::getUnsafe(); }

  ValueType getSafe() const noexcept { return super::getSafe(); }

  void setSafe(bool value, AUAudioFrameCount duration = 0) { super::setSafe(value ? 1.0 : 0.0, 0); }

  void checkForChange(AUAudioFrameCount duration) noexcept { super::checkForChange(0); }

  void stopRamping() noexcept { super::stopRamping(); }

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return super::getSafe(); }
};

} // end namespace DSPHeaders::Parameters
