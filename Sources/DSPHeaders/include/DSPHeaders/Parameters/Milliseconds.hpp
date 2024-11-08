// Copyright © 2022 Brad Howes. All rights reserved.

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

  explicit Milliseconds(AUValue milliseconds = 0.0, bool canRamp = true) noexcept
  : super(milliseconds, canRamp, Transformer::passthru, Transformer::passthru) {}
};

} // end namespace DSPHeaders::Parameters
