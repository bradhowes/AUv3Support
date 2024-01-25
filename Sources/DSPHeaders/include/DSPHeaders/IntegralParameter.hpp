// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BaseRampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Holds an integer value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
class IntegralParameter : public BaseRampingParameter {
public:
  using super = BaseRampingParameter;

  explicit IntegralParameter(AUValue init = 0.0) noexcept : super(Transformers::rounded(init), Transformers::rounded, Transformers::rounded) {}
};

} // end namespace DSPHeaders::Parameters
