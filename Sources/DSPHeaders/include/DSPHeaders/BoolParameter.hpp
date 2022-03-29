// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Holds a boolean value and handles conversion from/to AUValue representations.
 */
struct BoolParameter {

  BoolParameter() = default;
  explicit BoolParameter(bool init) noexcept : value_{init} {};
  ~BoolParameter() = default;

  void set(AUValue value) noexcept { value_ = value != 0.0; }

  AUValue get() const noexcept { return value_ ? 1.0 : 0.0; }

  operator bool() const noexcept { return value_; }

private:
  bool value_;

  BoolParameter(const BoolParameter&) = delete;
  BoolParameter(BoolParameter&&) = delete;
  BoolParameter& operator =(const BoolParameter&) = delete;
  BoolParameter& operator =(BoolParameter&&) = delete;
};

} // end namespace DSPHeaders::Parameters
