// Copyright © 2024-2025 Brad Howes. All rights reserved.

#import <concepts>
#import <type_traits>

#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BusBuffers.hpp"

namespace DSPHeaders {

/// Concept that limits a type to a numeric type. NOTE: this might need to be refined.
template <typename T>
concept Numeric = std::floating_point<T> || std::integral<T>;

/// Concept that requires the type to be an enumeration.
template <typename T>
concept EnumeratedType = std::is_enum_v<T>;

/// Concept that requires the type to to be convertible to a `size_t` value.
template <typename T>
concept SizableType = std::convertible_to<T, std::size_t>;

/// Concept that requires the type to have an `entity_size` static member which provides a `size_t` value.
template <typename T>
concept EntityDerivedType = requires { { T::entity_size } -> std::convertible_to<std::size_t>; };

/// Concept that requires the type to support random access indexing. I think this can be improved on.
template <typename T>
concept RandomAccessContainer = requires(T v) { { v.at(0) } -> std::convertible_to<typename T::value_type>; };

/// Concept definition for a Kernel class with an optional `doRenderingStateChanged` method.
template<typename T>
concept HasRenderingStateChangedT = requires(T a)
{
  { a.doRenderingStateChanged(false) } -> std::convertible_to<void>;
};

/// Concept definition for a Kernel class with an optional `doMIDIEvent` method.
template<typename T>
concept HasMIDIEventV1 = requires(T a, const AUMIDIEvent& midi)
{
  { a.doMIDIEvent(midi) } -> std::convertible_to<void>;
};

/// Concept definition for a Kernel class with an optional `doSetImmediateParameterValue` method.
template<typename T>
concept HasSetImmediateParameterValue = requires(T a, AUParameterAddress address, AUValue value,
                                                 AUAudioFrameCount duration)
{
  { a.doSetImmediateParameterValue(address, value, duration) } -> std::convertible_to<bool>;
};

/// Concept definition for a Kernel class with an optional `doSetPendingParameterValue` method.
template<typename T>
concept HasSetPendingParameterValue = requires(T a, AUParameterAddress address, AUValue value)
{
  { a.doSetPendingParameterValue(address, value) } -> std::convertible_to<bool>;
};

/// Concept definition for a Kernel class with an optional `doGetImmediateParameterValue` method.
template<typename T>
concept HasGetImmediateParameterValue = requires(T a, AUParameterAddress address)
{
  { a.doGetImmediateParameterValue(address) } -> std::convertible_to<AUValue>;
};

/// Concept definition for a Kernel class with an optional `doGetImmediateParameterValue` method.
template<typename T>
concept HasGetPendingParameterValue = requires(T a, AUParameterAddress address)
{
  { a.doGetPendingParameterValue(address) } -> std::convertible_to<AUValue>;
};

/// Concept definition for a valid Kernel class, one that provides method definitions for the functions
/// used by the EventProcessor template.
template<typename T>
concept IsViableKernelType = requires(T a, const AUParameterEvent& param, const AUMIDIEvent& midi, BusBuffers bb)
{
  { a.doRendering(bb, bb, AUAudioFrameCount(1) ) } -> std::convertible_to<void>;
};

}
