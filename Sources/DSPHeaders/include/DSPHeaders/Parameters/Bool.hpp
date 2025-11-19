// Copyright © 2022-2025 Brad Howes. All rights reserved.

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

   @param address the AUParameterAddress for the parameter
   @param value the value to hold
   */
  explicit Bool(AUParameterAddress address, bool value = false) noexcept
  : super(address, value, false, Transformer::boolIn, Transformer::passthru) {}

  template <EnumeratedType T>
  explicit Bool(T address, bool value = false) noexcept
  : Bool(DSPHeaders::valueOf(address), value) {}

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return super::getImmediate(); }
};

} // end namespace DSPHeaders::Parameters
