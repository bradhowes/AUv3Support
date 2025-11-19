// Copyright © 2024-2025 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import <functional>

namespace DSPHeaders {

struct TypeErasedKernel
{
  using ProcessAndRender = std::function<AUAudioUnitStatus(const AudioTimeStamp*,
                                                           UInt32,
                                                           NSInteger,
                                                           AudioBufferList*,
                                                           const AURenderEvent*,
                                                           AURenderPullInputBlock)>;
  TypeErasedKernel() : processAndRender{} {}

  TypeErasedKernel(ProcessAndRender par) : processAndRender{par} {}

  std::function<AUAudioUnitStatus(const AudioTimeStamp*, UInt32, NSInteger, AudioBufferList*, const AURenderEvent*,
                                  AURenderPullInputBlock)> processAndRender;
};

struct RenderBlockShim
{
  RenderBlockShim(TypeErasedKernel kernel) : kernel_{kernel} {}

  AUInternalRenderBlock internalRenderBlock() {
    if (kernel_.processAndRender) {
      return ^AUAudioUnitStatus(AudioUnitRenderActionFlags         *actionFlags,
                                const AudioTimeStamp               *timestamp,
                                AVAudioFrameCount                   frameCount,
                                NSInteger                           outputBusNumber,
                                AudioBufferList                    *outputData,
                                const AURenderEvent                *realtimeEventListHead,
                                AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        return kernel_.processAndRender(timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead,
                                        pullInputBlock);
      };
    } else {
      return ^AUAudioUnitStatus(AudioUnitRenderActionFlags         *actionFlags,
                                const AudioTimeStamp               *timestamp,
                                AVAudioFrameCount                   frameCount,
                                NSInteger                           outputBusNumber,
                                AudioBufferList                    *outputData,
                                const AURenderEvent                *realtimeEventListHead,
                                AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        return -1;
      };
    }
  }

  TypeErasedKernel kernel_;
};

}
