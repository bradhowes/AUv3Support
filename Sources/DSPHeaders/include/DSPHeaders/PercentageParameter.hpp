// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "RampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents a percentage. External values are [0-100] while internally it holds [0-1].
 */
template <typename ValueType = AUValue>
class PercentageParameter : private RampingParameter<ValueType> {
public:
  using super = RampingParameter<ValueType>;

  explicit PercentageParameter(ValueType value) noexcept : super(normalize(value)) {}

  PercentageParameter() = default;

  ~PercentageParameter() = default;

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the value in range [0-100] to use for the parameter
   @param duration the number of frames to transition over
   */
  void setUnsafe(ValueType value) noexcept { super::setUnsafe(normalize(value)); }

  /// @returns the current parameter value in range [0-100]
  ValueType getUnsafe() const noexcept { return super::getUnsafe() * 100.0; }

  void setSafe(ValueType value, AUAudioFrameCount duration) noexcept { super::setSafe(normalize(value), duration); }

  ValueType getSafe() const noexcept { return super::getSafe(); }

  ValueType frameValue(bool advance = true) noexcept { return super::frameValue(advance); }
  
  void checkForChange(AUAudioFrameCount duration) noexcept { super::checkForChange(); }

private:
  inline static constexpr ValueType normalize(ValueType value) noexcept { return std::clamp(value / 100.0, 0.0, 1.0); }
};

} // end namespace DSPHeaders::Parameters
