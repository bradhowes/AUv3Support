// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/EventProcessor.hpp"

using namespace DSPHeaders;

@interface SampleBufferTests : XCTestCase

@end

static AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
static AUAudioFrameCount maxFrames = 100;

@implementation SampleBufferTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  BusSampleBuffer buffer;
  XCTAssertEqual(buffer.capacity(), size_t(0));
  XCTAssertEqual(buffer.mutableAudioBufferList(), nullptr);

  buffer.allocate(format, maxFrames);
  XCTAssertEqual(buffer.capacity(), maxFrames);
  XCTAssertEqual(buffer.channelCount(), 2);
  XCTAssertNotEqual(buffer.mutableAudioBufferList(), nullptr);

  buffer.release();
  XCTAssertEqual(buffer.capacity(), maxFrames);
  XCTAssertEqual(buffer.channelCount(), 0);
  XCTAssertEqual(buffer.mutableAudioBufferList(), nullptr);
}

@end
