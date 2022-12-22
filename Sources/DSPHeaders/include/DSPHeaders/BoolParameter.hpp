// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Holds a boolean value and handles conversion from/to AUValue representations. Unlike other parameter representations,
 this one does not support ramping -- the change is instantaneous.
 */
template <typename ValueType = AUValue>
class BoolParameter {
public:
  
  explicit BoolParameter(bool init) noexcept : value_{init} {};

  explicit BoolParameter(ValueType init) noexcept : value_{init != 0.0 ? true : false} {};

  BoolParameter() = default;

  ~BoolParameter() = default;

  /**
   Set the new parameter value. Treat anything non-zero as `true` and 0.0 as `false`.

   @param value the new value to use
   */
  void set(ValueType value) noexcept { value_ = value != 0.0; }

  /// @returns 1.0 if `true` and 0.0 if `false`
  ValueType get() const noexcept { return value_ ? 1.0 : 0.0; }

  /// @returns the boolean state of the parameter
  operator bool() const noexcept { return value_; }

private:
  bool value_;
};

} // end namespace DSPHeaders::Parameters
