// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "DSPHeaders/BaseRampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents duration in milliseconds. No transform is applied to set/get values. Purely serves as
 a notational mechanism.
 */
class MillisecondsParameter : public BaseRampingParameter {
public:
  using super = BaseRampingParameter;

  explicit MillisecondsParameter(AUValue milliseconds = 0.0) noexcept : super(milliseconds, Transformers::passthru, Transformers::passthru) {}
};

} // end namespace DSPHeaders::Parameters
