// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/BufferFacet.hpp"

using namespace DSPHeaders;

@interface BufferFacetsTests : XCTestCase

@end

static AVAudioFormat* monoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:1];
static AVAudioFormat* stereoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
static AUAudioFrameCount maxFrames = 100;

@implementation BufferFacetsTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testMono {
  SampleBuffer buffer{"abc"};
  buffer.allocate(monoFormat, maxFrames);
  BufferFacet& facet{buffer.bufferFacet()};
  XCTAssertEqual(1, facet.channelCount());
  BusBuffers bb{facet.busBuffers()};
  XCTAssertTrue(bb.isMono());
}

- (void)testStereo {
  SampleBuffer buffer{"abc"};
  buffer.allocate(stereoFormat, maxFrames);
  BufferFacet& facet{buffer.bufferFacet()};
  XCTAssertEqual(2, facet.channelCount());
  BusBuffers bb{facet.busBuffers()};
  XCTAssertTrue(bb.isStereo());
}

- (void)testChannelCount {
  SampleBuffer monoBuffer{"abc"};
  monoBuffer.allocate(monoFormat, maxFrames);
  SampleBuffer stereoBuffer{"abc"};
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BufferFacet facet{"abc"};
  facet.setChannelCount(1);
  XCTAssertNoThrow(facet.setBufferList(monoBuffer.mutableAudioBufferList()));

  facet.setChannelCount(2);
  XCTAssertNoThrow(facet.setBufferList(stereoBuffer.mutableAudioBufferList()));

  facet.setChannelCount(1);
  XCTAssertThrows(facet.setBufferList(stereoBuffer.mutableAudioBufferList()));
}

- (void)testFrameCount {
  SampleBuffer monoBuffer{"abc"};
  monoBuffer.allocate(monoFormat, maxFrames);
  SampleBuffer stereoBuffer{"abc"};
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BufferFacet facet{"abc"};
  facet.setChannelCount(1);
  facet.setBufferList(monoBuffer.mutableAudioBufferList());
  facet.setFrameCount(10);
  XCTAssertEqual(10 * sizeof(float), monoBuffer.mutableAudioBufferList()->mBuffers[0].mDataByteSize);

  facet.setChannelCount(2);
  facet.setBufferList(stereoBuffer.mutableAudioBufferList());
  facet.setFrameCount(13);
  XCTAssertEqual(13 * sizeof(float), stereoBuffer.mutableAudioBufferList()->mBuffers[0].mDataByteSize);
  XCTAssertEqual(13 * sizeof(float), stereoBuffer.mutableAudioBufferList()->mBuffers[1].mDataByteSize);
}

- (void)testOffset {
  SampleBuffer stereoBuffer{"abc"};
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BufferFacet facet{"abc"};
  facet.setChannelCount(2);
  facet.setBufferList(stereoBuffer.mutableAudioBufferList());
  BusBuffers bb1{facet.busBuffers()};
  XCTAssertTrue(bb1.isValid());
  XCTAssertTrue(bb1.isStereo());

  bb1.addAll(0, 1.0);
  bb1.addAll(1, 2.0);
  bb1.addAll(2, 3.0);
  bb1.addAll(3, 4.0);

  facet.setOffset(1);
  BusBuffers bb2{facet.busBuffers()};
  bb2.addAll(0, 4.0);
  bb2.addAll(1, 5.0);

  float* left = (float*)(stereoBuffer.mutableAudioBufferList()->mBuffers[0].mData);
  float* right = (float*)(stereoBuffer.mutableAudioBufferList()->mBuffers[1].mData);
  XCTAssertEqual(1.0, left[0]);
  XCTAssertEqual(1.0, right[0]);
  XCTAssertEqual(6.0, left[1]);
  XCTAssertEqual(6.0, right[1]);
  XCTAssertEqual(8.0, left[2]);
  XCTAssertEqual(8.0, right[2]);
  XCTAssertEqual(4.0, left[3]);
  XCTAssertEqual(4.0, right[3]);
}

- (void)testUnlink {
  SampleBuffer stereoBuffer{"abc"};
  stereoBuffer.allocate(stereoFormat, maxFrames);

  BufferFacet facet{"abc"};
  facet.unlink();
  BusBuffers bb{facet.busBuffers()};
  XCTAssertFalse(bb.isValid());
}

@end
