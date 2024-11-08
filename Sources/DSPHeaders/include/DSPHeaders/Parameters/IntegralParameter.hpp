// Copyright © 2022 Brad Howes. All rights reserved.

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

  explicit Integral(AUValue init = 0.0) noexcept
  : super(Transformer::rounded(init), false, Transformer::rounded, Transformer::rounded) {}
};

} // end namespace DSPHeaders::Parameters
