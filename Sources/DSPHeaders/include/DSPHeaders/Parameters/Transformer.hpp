// Copyright © 2022-2024 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <atomic>

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Parameters {

/**
 Collecton of AUValue transforms that are used to manage values in parameters.
 */
struct Transformer {

  /**
   A no-op transformer

   @param value the value to transform
   @returns transformed value
   */
  static AUValue passthru(AUValue value) noexcept { return value; }

  /**
   A transformer of percentage values (0-100) into a normalized one (0.0-1.0)

   @param value the value to transform
   @returns transformed value
   */
  static AUValue percentageIn(AUValue value) noexcept { return std::clamp(value / 100.0f, 0.0f, 1.0f); }

  /**
   A transformer of normalized values (0.0-1.0) into percentages (0-100)

   @param value the value to transform
   @returns transformed value
   */
  static AUValue percentageOut(AUValue value) noexcept { return value * 100.0f; }

  /**
   A transformer of floating-point values into a boolean, where 0.0 means false and anything else 1.0.

   @param value the value to transform
   @returns transformed value
   */
  static AUValue boolIn(AUValue value) noexcept { return value < 0.5 ? 0.0f : 1.0f; }

  /**
   A transformer of floating-point values into integral ones.

   @param value the value to transform
   @returns transformed value
   */
  static AUValue rounded(AUValue value) { return std::round(value); }
};

} // end namespace DSPHeaders::Parameters
