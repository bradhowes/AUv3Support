// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "RampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents duration in milliseconds. No transform is applied to set/get values. Purely serves as
 a notational mechanism.
 */
template <typename ValueType = AUValue>
class MillisecondsParameter : public RampingParameter<ValueType> {
public:
  using super = RampingParameter<ValueType>;

  explicit MillisecondsParameter(ValueType milliseconds) noexcept : super(milliseconds) {}

  MillisecondsParameter() = default;

  ~MillisecondsParameter() = default;
};

} // end namespace DSPHeaders::Parameters
