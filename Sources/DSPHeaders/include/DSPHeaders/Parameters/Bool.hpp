// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 A pseudo-bool parameter that relies on an AUValue value to determine true or false state. It has a modified `startRamp` method
 so that pending changes will be instantaneous when they are applied.
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
