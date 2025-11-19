// Copyright © 2022-2025 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Manages an AUValue parameter that can transition from one value to another over some number of frames.
 */
class Float : public Base {
public:
  using super = Base;

  /**
   Construct a new parameter.

   @param address the AUParameterAddress for the parameter
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  explicit Float(AUParameterAddress address, AUValue value = 0.0, bool canRamp = true) noexcept
  : super(address, value, canRamp, Transformer::passthru, Transformer::passthru) {}

  /**
   Construct a new parameter.

   @param address enumeration that holds an AUParameterAddress value
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  template <EnumeratedType T>
  explicit Float(T address, AUValue value = 0.0, bool canRamp = true) noexcept
  : Float(DSPHeaders::valueOf(address), value, canRamp) {}
};

} // end namespace DSPHeaders::Parameters
