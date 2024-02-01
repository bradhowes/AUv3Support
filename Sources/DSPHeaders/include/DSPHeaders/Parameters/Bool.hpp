// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Holds a boolean value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
class Bool : public Base {
public:
  using super = Base;

  /**
   Construct new instance from POD value.

   @param init the value to hold
   */
  explicit Bool(bool init = false) noexcept : super(Transformer::boolIn(init), Transformer::boolIn, Transformer::passthru) {}

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return super::get(); }

private:

  void startRamp(AUValue pendingValue, AUAudioFrameCount duration) noexcept override { super::startRamp(pendingValue, 0); }
};

} // end namespace DSPHeaders::Parameters
