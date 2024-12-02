// Copyright © 2022-2024 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Holds an integer value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
class Integral : public Base {
public:
  using super = Base;

  /**
   Construct a new parameter.

   @param address the AUParameterAddress for the parameter
   @param value the starting value for the parameter
   */
  explicit Integral(AUParameterAddress address, AUValue value = 0.0) noexcept
  : super(address, value, false, Transformer::rounded, Transformer::rounded) {}

  /**
   Construct a new parameter.

   @param address enumeration that holds an AUParameterAddress value
   @param value the starting value for the parameter
   @param canRamp if `true` then a parameter change will happen over some number of rendered samples
   */
  template <EnumeratedType T>
  explicit Integral(T address, AUValue value = 0.0) noexcept
  : Integral(DSPHeaders::valueOf(address), value) {}
};

} // end namespace DSPHeaders::Parameters
