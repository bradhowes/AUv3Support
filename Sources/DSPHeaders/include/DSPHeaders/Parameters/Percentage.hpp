// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents a percentage. External values are [0-100] while internally it holds [0-1].
 */
class Percentage : public Base {
public:
  using super = Base;

  explicit Percentage(AUValue value = 0.0) noexcept : super(Transformer::passthru(value), Transformer::percentageIn, Transformer::percentageOut) {}
};

} // end namespace DSPHeaders::Parameters
