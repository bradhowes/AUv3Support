// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/BaseRampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Holds a boolean value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
class BoolParameter : public BaseRampingParameter {
public:
  using super = BaseRampingParameter;

  /**
   Construct new instance from POD value.

   @param init the value to hold
   */
  explicit BoolParameter(bool init = false) noexcept : super(Transformers::boolIn(init), Transformers::boolIn, Transformers::passthru) {}

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return super::getSafe(); }
};

} // end namespace DSPHeaders::Parameters
