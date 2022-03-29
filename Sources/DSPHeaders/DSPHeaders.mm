// Copyright © 2022 Brad Howes. All rights reserved.

#include "DSPHeaders/Biquad.hpp"
#include "DSPHeaders/BoolParameter.hpp"
#include "DSPHeaders/BufferFacet.hpp"
#include "DSPHeaders/ConstMath.hpp"
#include "DSPHeaders/DelayBuffer.hpp"
#include "DSPHeaders/DSP.hpp"
#include "DSPHeaders/EventProcessor.hpp"
#include "DSPHeaders/LFO.hpp"
#include "DSPHeaders/MillisecondsParameter.hpp"
#include "DSPHeaders/PercentageParameter.hpp"
#include "DSPHeaders/PhaseShifter.hpp"
#include "DSPHeaders/RampingParameter.hpp"
#include "DSPHeaders/SampleBuffer.hpp"

using namespace DSPHeaders;
using namespace DSPHeaders::DSP;

static constexpr size_t TableSize = Interpolation::Cubic4thOrder::TableSize;

static constexpr double generator0(size_t index) {
  auto x = double(index) / double(TableSize);
  auto x_05 = 0.5 * x;
  auto x2 = x * x;
  auto x3 = x2 * x;
  auto x3_05 = 0.5 * x3;
  return -x3_05 + x2 - x_05;
}

static constexpr double generator1(size_t index) {
  auto x = double(index) / double(TableSize);
  auto x2 = x * x;
  auto x3 = x2 * x;
  auto x3_15 = 1.5 * x3;
  return x3_15 - 2.5 * x2 + 1.0;
}

static constexpr double generator2(size_t index) {
  auto x = double(index) / double(TableSize);
  auto x_05 = 0.5 * x;
  auto x2 = x * x;
  auto x3 = x2 * x;
  auto x3_15 = 1.5 * x3;
  return -x3_15 + 2.0 * x2 + x_05;
}

static constexpr double generator3(size_t index) {
  auto x = double(index) / double(TableSize);
  auto x2 = x * x;
  auto x3 = x2 * x;
  auto x3_05 = 0.5 * x3;
  return x3_05 - 0.5 * x2;
}

using WeightsEntry = Interpolation::Cubic4thOrder::WeightsEntry;

static constexpr WeightsEntry generator(size_t index) {
  return WeightsEntry{generator0(index), generator1(index), generator2(index), generator3(index)};
}

std::array<WeightsEntry,TableSize> Interpolation::Cubic4thOrder::weights_ = ConstMath::make_array<WeightsEntry, TableSize>(generator);
