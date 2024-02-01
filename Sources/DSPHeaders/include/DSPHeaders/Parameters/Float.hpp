// Copyright © 2022 Brad Howes. All rights reserved.

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

   @param value the starting value for the parameter
   */
  Float(AUValue value = 0.0) noexcept : super(Transformer::passthru(value), Transformer::passthru, Transformer::passthru) {}
};

} // end namespace DSPHeaders::Parameters
