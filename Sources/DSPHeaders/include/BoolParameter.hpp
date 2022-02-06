// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import <AVFoundation/AVFoundation.h>

/**
 Holds a boolean value and handles conversion from/to AUValue representations.
 */
struct BoolParameter {

  BoolParameter() = default;
  explicit BoolParameter(bool init) : value_{init} {};
  ~BoolParameter() = default;

  void set(AUValue value) { value_ = value != 0.0; }

  AUValue get() const { return value_ ? 1.0 : 0.0; }

  operator bool() const { return value_; }

private:
  bool value_;

  BoolParameter(const BoolParameter&) = delete;
  BoolParameter(BoolParameter&&) = delete;
  BoolParameter& operator =(const BoolParameter&) = delete;
  BoolParameter& operator =(BoolParameter&&) = delete;
};


