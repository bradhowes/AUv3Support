// Copyright © 2022-2024 Brad Howes. All rights reserved.

#include "DSPHeaders/DSP.hpp"

using namespace DSPHeaders;
using namespace DSPHeaders::DSP;

static constexpr size_t TableSize = Interpolation::Cubic4thOrder::TableSize;

static constexpr double x1(size_t index) { return double(index) / double(TableSize); }
static constexpr double x2(double x1) { return x1 * x1; }
static constexpr double x3(double x1, double x2) { return x1 * x2; }

static constexpr double generator0(size_t index) {
  auto x1_ = x1(index);
  auto x2_ = x2(x1_);
  auto x3_ = x3(x1_, x2_);
  auto x_05 = 0.5 * x1_;
  auto x3_05 = 0.5 * x3_;
  return -x3_05 + x2_ - x_05;
}

static constexpr double generator1(size_t index) {
  auto x1_ = x1(index);
  auto x2_ = x2(x1_);
  auto x3_ = x3(x1_, x2_);
  auto x3_15 = 1.5 * x3_;
  return x3_15 - 2.5 * x2_ + 1.0;
}

static constexpr double generator2(size_t index) {
  auto x1_ = x1(index);
  auto x2_ = x2(x1_);
  auto x3_ = x3(x1_, x2_);
  auto x_05 = 0.5 * x1_;
  auto x3_15 = 1.5 * x3_;
  return -x3_15 + 2.0 * x2_ + x_05;
}

static constexpr double generator3(size_t index) {
  auto x1_ = x1(index);
  auto x2_ = x2(x1_);
  auto x3_ = x3(x1_, x2_);
  auto x3_05 = 0.5 * x3_;
  return x3_05 - 0.5 * x2_;
}

using WeightsEntry = Interpolation::Cubic4thOrder::WeightsEntry;

static constexpr WeightsEntry generator(size_t index) {
  return WeightsEntry{generator0(index), generator1(index), generator2(index), generator3(index)};
}

WeightsEntry DSPHeaders::DSP::Interpolation::Cubic4thOrder::generator(size_t index) { return ::generator(index); }

std::array<WeightsEntry, TableSize> Interpolation::Cubic4thOrder::weights_ =
  ConstMath::make_array<WeightsEntry, TableSize>(generator);
