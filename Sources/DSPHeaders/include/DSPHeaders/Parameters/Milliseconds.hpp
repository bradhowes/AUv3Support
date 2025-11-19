// Copyright © 2022-2025 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents duration in milliseconds. No transform is applied to set/get values. Purely serves as
 a notational mechanism.
 */
class Milliseconds : public Base {
public:
  using super = Base;

  /**
   Construct a new parameter.

   @param address the AUParameterAddress for the parameter
   @param milliseconds the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  explicit Milliseconds(AUParameterAddress address, AUValue milliseconds = 0.0, bool canRamp = true) noexcept
  : super(address, milliseconds, canRamp, Transformer::passthru, Transformer::passthru) {}

  /**
   Construct a new parameter.

   @param address enumeration that holds an AUParameterAddress value
   @param milliseconds the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  template <EnumeratedType T>
  explicit Milliseconds(T address, AUValue milliseconds = 0.0, bool canRamp = true) noexcept
  : Milliseconds(DSPHeaders::valueOf(address), milliseconds, canRamp) {}
};

} // end namespace DSPHeaders::Parameters
