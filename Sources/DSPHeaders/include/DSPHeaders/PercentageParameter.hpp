// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/BaseRampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents a percentage. External values are [0-100] while internally it holds [0-1].
 */
class PercentageParameter : public BaseRampingParameter {
public:
  using super = BaseRampingParameter;

  explicit PercentageParameter(AUValue value = 0.0) noexcept : super(Transformers::passthru(value), Transformers::percentageIn, Transformers::percentageOut) {}
};

} // end namespace DSPHeaders::Parameters
