// Copyright © 2024-2025 Brad Howes. All rights reserved.

#import <type_traits>

#import "DSPHeaders/Concepts.hpp"

namespace DSPHeaders {

/**
 Convert an enum value into its underlying integral type.
 */
template <EnumeratedType T>
constexpr auto valueOf(T index) noexcept { return static_cast<typename std::underlying_type<T>::type>(index); };

}
