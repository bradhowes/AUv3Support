// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>

/**
 Collection of compile-time methods that can be used to create lookup tables for various DSP operations.
 */
namespace DSPHeaders::ConstMath {

// Based on work from https://github.com/lakshayg/compile_time (no specific license)
// and https://github.com/kthohr/gcem (Apache license). Note that many of the comments below are mine.
//
// Here is the GCEM license in full:

/*################################################################################
 ##
 ##   Copyright (C) 2016-2022 Keith O'Hara
 ##
 ##   This file is part of the GCE-Math C++ library.
 ##
 ##   Licensed under the Apache License, Version 2.0 (the "License");
 ##   you may not use this file except in compliance with the License.
 ##   You may obtain a copy of the License at
 ##
 ##       http://www.apache.org/licenses/LICENSE-2.0
 ##
 ##   Unless required by applicable law or agreed to in writing, software
 ##   distributed under the License is distributed on an "AS IS" BASIS,
 ##   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 ##   See the License for the specific language governing permissions and
 ##   limitations under the License.
 ##
 ################################################################################*/

using llint_t = long long;

/// If type of template argument is an integral type, use `double` type. Otherwise, the template arg.
template<typename T>
using IntegralAsDouble = typename std::conditional_t<std::is_integral_v<T>, double, T>;

/// Identify the common type for the given template arguments.
template<typename ...T>
using CommonType = typename std::common_type_t<T...>;

/// If common type is an integral type, use `double` type. Otherwise, the common type.
template<typename ...T>
using CommonIntegralAsDouble = IntegralAsDouble<CommonType<T...>>;

/// Collection of constants use by the routines that follow.
template <typename T>
struct Constants {
  /// Euler's constant
  static constexpr T e = T(2.7182818284590452353602874713526624977572L);
  /// Natural logarithm of 2.0
  static constexpr T ln2 = T(0.6931471805599453094172321214581765680755L);
  /// Natural logarithm of 10.0
  static constexpr T ln10 = T(2.3025850929940456840179914546843642076011L);
  /// PI
  static constexpr T PI = T(3.1415926535897932384626433832795028841972L);
  /// 2 * PI
  static constexpr T TwoPI = 2 * PI;
  /// PI / 2
  static constexpr T HalfPI = PI / 2.0;
  /// PI / 4
  static constexpr T QuarterPI = PI / 4.0;
};

/**
 Helper function used to initialize a constexpr array with values generated at compile time. Template
 parameter `T` is the type of the values to generate (the return value of the given function), `N` is
 is the number of elements to generate, and `Generator` is the type of the function that will be called
 to generate the values.

 @param gen the function to call to generate values for the table. It will be called `N` times.
 @returns initialized std::array
 */
template <typename T, std::size_t N, typename Generator>
constexpr std::array<T, N> make_array(Generator gen) noexcept {
  std::array<T, N> table = {};
  for (std::size_t i = 0; i != N; ++i) table[i] = gen(i);
  return table;
}

/**
 Obtain the absolute value of a give value. Properly handles signed zeros.

 @param x the value to process
 @returns the non-negative version of the given value
 */
template<typename T>
constexpr T abs(const T x) noexcept { return x == T(0) ? T(0) : x < T(0) ? -x : x; }

/**
 Obtain a value multiplied with itself

 @param x the value to work with
 @returns x * x
 */
template <typename T>
constexpr T squared(T x) noexcept { return x * x; }

/**
 Update a value in radians so that it is within the range (-PI, PI].

 @param theta the value to normalize
 @returns -PI < value <= PI
 */
template <typename T>
constexpr T normalizedRadians(T theta) noexcept {
  constexpr auto PI = Constants<T>::PI;
  constexpr auto TwoPI = Constants<T>::TwoPI;
  return (theta <= -PI) ? normalizedRadians(theta + TwoPI) : (theta > PI) ? normalizedRadians(theta - TwoPI) : theta;
}

/**
 Determine if the given value is NaN

 @param x the value to check
 @returns true if so
 */
template<typename T>
constexpr bool is_nan(const T x) noexcept { return x != x; }

// Implementation details (called `internal` in the GCEM code)

namespace detail {

/**
 Obtain a normalized mantissa, one that is >= 1 and <= 10.

 @param x the value to work with
 @returns the normalized value
 */
template<typename T>
constexpr T mantissa(const T x) noexcept {
  return x < T(1) ? mantissa(x * T(10)) : x > T(10) ? mantissa(x / T(10)) : x;
}

template <typename Real>
constexpr Real sin_cfrac(Real x2, int k = 2, int n = 40) {
  return (n == 0) ? k * (k + 1) - x2 : k * (k + 1) - x2 + (k * (k + 1) * x2) / sin_cfrac(x2, k + 2, n - 1);
}

template <typename Real>
constexpr Real exp_frac_helper(Real x2, int iter = 5, int k = 6) {
  return (iter > 0) ? k + x2 / exp_frac_helper(x2, iter - 1, k + 4) : k + x2 / (k + 4);
}

template <typename Real>
constexpr Real exp_frac(Real x) { return (x != 0) ? 1 + 2 * x / (2 - x + (x * x) / exp_frac_helper(x * x)) : 1; }

/**
 Normalize x ^ y so that x is between 1 and 10.

 @param x the value being raised to a power
 @param y the exponent being used
 @returns the final exponent when `x` is between 1 and 10.s
 */
template<typename T>
constexpr llint_t find_exponent(const T x, const llint_t y) noexcept {
  return(x < T(1) ? find_exponent(x * 10L, y - 1L) : x > 10L ? find_exponent(x / 10L, y + 1L) : y);
}

// continued fraction seems to be a better approximation for small x
// see http://functions.wolfram.com/ElementaryFunctions/Log/10/0005/

template<typename T>
constexpr T log_cf_main(const T xx, const int depth) noexcept {
  const auto d2 = T(2 * depth - 1);
  return depth < 25 ? d2 - T(depth * depth) * xx / log_cf_main(xx, depth + 1) : d2;
}

template<typename T>
constexpr T log_cf_begin(const T x) noexcept { return T(2) * x / log_cf_main(x * x, 1); }

template<typename T>
constexpr T log_main(const T x) noexcept { return log_cf_begin((x - T(1)) / (x + T(1))); }

constexpr long double log_mantissa_integer(const int x) noexcept {
  return(x == 2  ? 0.6931471805599453094172321214581765680755L :
         x == 3  ? 1.0986122886681096913952452369225257046475L :
         x == 4  ? 1.3862943611198906188344642429163531361510L :
         x == 5  ? 1.6094379124341003746007593332261876395256L :
         x == 6  ? 1.7917594692280550008124773583807022727230L :
         x == 7  ? 1.9459101490553133051053527434431797296371L :
         x == 8  ? 2.0794415416798359282516963643745297042265L :
         x == 9  ? 2.1972245773362193827904904738450514092950L :
         x == 10 ? 2.3025850929940456840179914546843642076011L :
         0.0L);
}

template<typename T>
constexpr T log_mantissa(const T x) noexcept {
  // divide by the integer part of x, which will be in [1,10], then adjust using tables
  return log_main(x / T(static_cast<int>(x))) + T(log_mantissa_integer(static_cast<int>(x)));
}

template<typename T>
constexpr T log_breakup(const T x) noexcept {
  // x = a*b, where b = 10^c
  return log_mantissa(mantissa(x)) + T(Constants<T>::ln10) * T(find_exponent(x, 0));
}

template<typename T>
constexpr T log_check(const T x) noexcept {
  return(is_nan(x) ?
         std::numeric_limits<T>::quiet_NaN() :
         // x < 0
         x < T(0) ?
         std::numeric_limits<T>::quiet_NaN() :
         // x ~= 0
         std::numeric_limits<T>::min() > x ?
         - std::numeric_limits<T>::infinity() :
         // indistinguishable from 1
         std::numeric_limits<T>::min() > abs(x - T(1)) ?
         T(0) :
         //
         x == std::numeric_limits<T>::infinity() ?
         std::numeric_limits<T>::infinity() :
         // else
         (x < T(0.5) || x > T(1.5)) ?
         // if
         log_breakup(x) :
         // else
         log_main(x));
}

template<typename T>
constexpr
IntegralAsDouble<T>
log_integral_check(const T x)
noexcept
{
  return(std::is_integral_v<T> ? \
         x == T(0) ? \
         - std::numeric_limits<IntegralAsDouble<T>>::infinity() :
         x > T(1) ? \
         log_check( static_cast<IntegralAsDouble<T>>(x) ) :
         static_cast<IntegralAsDouble<T>>(0) :
         log_check( static_cast<IntegralAsDouble<T>>(x) ) );
}

}  // namespace detail

/**
 Obtain the sine value for a given argument in radians
 */
template <typename Real>
constexpr Real sin(Real x) {
  const auto norm2 = squared(normalizedRadians(x));
  return normalizedRadians(x) / (1 + norm2 / detail::sin_cfrac(norm2));
}

/**
 Obtain the `floor` value of a given floating-point value. This is the largest integral value that is <= the
 given value.

 @param x the value to work with
 @returns largest integral value <= x
 */
template <typename Real, typename Integer = long long>
constexpr Integer floor(Real x) {
  if constexpr (std::is_integral_v<Real>) { return static_cast<Integer>(x); }
  return static_cast<Integer>(x) - (static_cast<Integer>(x) > x);
}

/**
 Obtain the `ceiling` value of a given floating-point value. This is the smallest integral value that is >= the
 given value.

 @param x the value to work with
 @returns smallest integral value >= x
 */
template <typename Real, typename Integer = long long>
constexpr Integer ceil(Real x) {
  if constexpr (std::is_integral_v<Real>) { return static_cast<Integer>(x); }
  return static_cast<Integer>(x) + (static_cast<Integer>(x) < x);
}

/**
 Determine if the given integral value is even. NOTE: this is only supported on integral types.

 @param x the value to check
 @returns true if so
 */
template <typename Integer>
constexpr bool is_even(Integer x) {
  static_assert(std::is_integral_v<Integer>, "is_even is defined only for integer types");
  return x % 2 == 0;
}

/**
 Obtain the value of a ^ n where `n` is an integral value.

 @param a the base value to raise by a power
 @param n the exponent to apply
 */
template <typename Real, typename Integer>
constexpr Real ipow(Real a, Integer n) {
  static_assert(std::is_integral_v<Integer>, "ipow supports only integral powers");
  return
  (n <  0) ? 1 / ipow(a, -n)        :
  (n == 0) ? 1                      :
  (n == 1) ? a                      :
  (a == 2) ? Real(Integer(1) << n)  :
  (is_even(n)) ? ipow(a * a, n / 2) :
  a * ipow(a * a, (n - 1) / 2);
}

/**
 Obtain the value of e ^ x.

 @param x the exponent to use
 @returns e ^ x
 */
template <typename Real>
constexpr Real exp(Real x) { return ipow(Constants<Real>::e, floor(x)) * detail::exp_frac(x - floor(x)); }

/**
 * Compile-time natural logarithm function
 *
 * @param x a real-valued input.
 * @returns natural logarithm of given value
 */

template<typename T>
constexpr IntegralAsDouble<T> log(const T x) noexcept { return detail::log_integral_check(x); }

/**
 Compile-time base-10 logarithm.

 @param x value to work with
 @returns log10(x) = log(x) / log(10)
 */
template<typename T>
constexpr IntegralAsDouble<T> log10(const T x) noexcept { return detail::log_integral_check(x) / Constants<T>::ln10; }

/**
 Compile-time pow function that calculates x ^ y.

 @param x the base value
 @param y the exponent
 @returns x ^ y = exp(y * log(x))
 */
template <typename Real>
constexpr Real pow(Real x, Real y) noexcept { return exp(y * log(x)); }

} // end namespace ConstMath
