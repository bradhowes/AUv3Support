// Copyright © 2022-2024 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents a percentage. External values are [0-100] while internally it holds [0-1].
 */
class Percentage : public Base {
public:
  using super = Base;

  /**
   Construct a new parameter.

   @param address the AUParameterAddress for the parameter
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  explicit Percentage(AUParameterAddress address, AUValue value = 0.0, bool canRamp = true) noexcept
  : super(address, value, canRamp, Transformer::percentageIn, Transformer::percentageOut) {}

  /**
   Construct a new parameter.

   @param address enumeration that holds an AUParameterAddress value
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  template <EnumeratedType T>
  explicit Percentage(T address, AUValue value = 0.0, bool canRamp = true) noexcept
  : Percentage(DSPHeaders::valueOf(address), value, canRamp) {}
};

} // end namespace DSPHeaders::Parameters
