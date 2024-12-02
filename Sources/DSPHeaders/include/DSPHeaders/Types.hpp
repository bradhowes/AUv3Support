//
//  Types.hpp.cpp
//  AUv3Support
//
//  Created by Brad Howes on 12/1/24.
//

#import "DSPHeaders/Concepts.hpp"

namespace DSPHeaders {

/**
 Convert an enum value into its underlying integral type.
 */
template <EnumeratedType T>
constexpr auto valueOf(T index) noexcept { return static_cast<typename std::underlying_type<T>::type>(index); };

}
