// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 A pseudo-bool parameter that relies on an AUValue value to determine true or false state.
 */
class Bool : public Base {
public:
  using super = Base;

  /**
   Construct new instance from POD value.

   @param init the value to hold
   */
  explicit Bool(bool init = false) noexcept
  : super(Transformer::boolIn(init), false, Transformer::boolIn, Transformer::passthru) {}

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return super::get(); }
};

} // end namespace DSPHeaders::Parameters
