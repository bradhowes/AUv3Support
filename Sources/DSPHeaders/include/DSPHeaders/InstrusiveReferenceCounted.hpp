#pragma once

#import <atomic>

namespace DSPHeaders {

/**
 Manager of a reference counter for an instance of a class T. Used when importing C++ classes as Swift reference
 types.
 */
template<class T>
class IntrusiveReferenceCounted {
public:

  /// Construct instance with initial reference count
  IntrusiveReferenceCounted() : intrusiveReferenceCounter_(1) {}

  /// Increment the reference count for the instance.
  void instrusiveReferenceCountedRetain() noexcept { ++intrusiveReferenceCounter_; }

  /// Decrement the reference count for the instance. If it was 1 (or less) then delete the instance.
  void instrusiveReferenceCountedRelease() noexcept {
    if (intrusiveReferenceCounter_ < 2) {
      delete this;
    } else {
      --intrusiveReferenceCounter_;
    }
  }

private:
  std::atomic<int> intrusiveReferenceCounter_;
};

}
