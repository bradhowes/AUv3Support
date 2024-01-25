#pragma once

#import <libkern/OSAtomic.h>
#import <atomic>
#import <cmath>

#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BaseRampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manages a parameter value that can transition from one value to another over some number of frames.
 */
class RampingParameter : public BaseRampingParameter {
public:
  using super = BaseRampingParameter;

  /**
   Construct a new parameter.

   @param initialValue the starting value for the parameter
   */
  RampingParameter(AUValue value = 0.0) noexcept : super(Transformers::passthru(value), Transformers::passthru, Transformers::passthru) {}
};

} // end namespace DSPHeaders::Parameters
