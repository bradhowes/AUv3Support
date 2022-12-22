// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Holds an integer value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
template <typename ValueType = AUValue>
class IntegralParameter {
public:
  
  static int round(ValueType value) { return int(std::round(value)); }

  IntegralParameter() = default;

  explicit IntegralParameter(ValueType init) noexcept : value_{round(init)} {};

  ~IntegralParameter() = default;

  /**
   Set the new parameter value.

   @param value the new value to use
   */
  void set(ValueType value) noexcept { value_ = round(value); }

  /// @returns current value
  ValueType get() const noexcept { return value_; }

private:
  int value_;
};

} // end namespace DSPHeaders::Parameters
