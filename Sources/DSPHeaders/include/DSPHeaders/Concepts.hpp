// Copyright © 2024 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders {

/**
 Concept definition for a Kernel class with an optional `doRenderingStateChanged` method.
 */
template<typename T>
concept HasRenderingStateChangedT = requires(T a)
{
  { a.doRenderingStateChanged(false) } -> std::convertible_to<void>;
};

/**
 Concept definition for a Kernel class with an optional `doMIDIEvent` method.
 */
template<typename T>
concept HasMIDIEventV1 = requires(T a, const AUMIDIEvent& midi)
{
  { a.doMIDIEvent(midi) } -> std::convertible_to<void>;
};

/**
 Concept definition for a Kernel class with an optional `doSetImmediateParameterValue` method.
 */
template<typename T>
concept HasSetImmediateParameterValue = requires(T a, AUParameterAddress address, AUValue value,
                                                 AUAudioFrameCount duration)
{
  { a.doSetImmediateParameterValue(address, value, duration) } -> std::convertible_to<bool>;
};

/**
 Concept definition for a Kernel class with an optional `doSetPendingParameterValue` method.
 */
template<typename T>
concept HasSetPendingParameterValue = requires(T a, AUParameterAddress address, AUValue value)
{
  { a.doSetPendingParameterValue(address, value) } -> std::convertible_to<bool>;
};

/**
 Concept definition for a Kernel class with an optional `doGetImmediateParameterValue` method.
 */
template<typename T>
concept HasGetImmediateParameterValue = requires(T a, AUParameterAddress address)
{
  { a.doGetImmediateParameterValue(address) } -> std::convertible_to<AUValue>;
};

/**
 Concept definition for a Kernel class with an optional `doGetImmediateParameterValue` method.
 */
template<typename T>
concept HasGetPendingParameterValue = requires(T a, AUParameterAddress address)
{
  { a.doGetPendingParameterValue(address) } -> std::convertible_to<AUValue>;
};

/**
 Concept definition for a valid Kernel class, one that provides method definitions for the functions
 used by the EventProcessor template.
 */
template<typename T>
concept IsViableKernelType = requires(T a, const AUParameterEvent& param, const AUMIDIEvent& midi, BusBuffers bb)
{
  { a.doRendering(NSInteger(1), bb, bb, AUAudioFrameCount(1) ) } -> std::convertible_to<void>;
};

}
