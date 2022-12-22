// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <cmath>
#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Holds a integer value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
struct IntegralParameter {

  static int round(AUValue value) { return int(std::round(value)); }

  IntegralParameter() = default;
  
  explicit IntegralParameter(AUValue init) noexcept : value_{round(init)} {};

  ~IntegralParameter() = default;

  /**
   Set the new parameter value.

   @param value the new value to use
   */
  void set(AUValue value) noexcept { value_ = round(value); }

  /// @returns current value
  AUValue get() const noexcept { return value_; }

private:
  int value_;
};

} // end namespace DSPHeaders::Parameters
