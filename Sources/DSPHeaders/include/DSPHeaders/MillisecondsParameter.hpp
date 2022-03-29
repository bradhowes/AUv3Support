// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "RampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents duration in milliseconds. No transform is applied to set/get values. Purely serves as
 a notational mechanism.
 */
template <typename T>
struct MillisecondsParameter : public RampingParameter<T> {
public:
  using super = RampingParameter<T>;

  MillisecondsParameter() = default;
  explicit MillisecondsParameter(T milliseconds) noexcept : super(milliseconds) {}
  ~MillisecondsParameter() = default;
};

} // end namespace DSPHeaders::Parameters
