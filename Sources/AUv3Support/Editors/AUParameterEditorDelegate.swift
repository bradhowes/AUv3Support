// Copyright © 2021-2024 Brad Howes. All rights reserved.

/**
 Delegate protocol for an AUParameterEditor
 */
@MainActor
public protocol AUParameterEditorDelegate: AnyObject {

  /**
   Notification when the editor finishes editing of a value.

   - parameter changed: true if the value changed
   */
  func parameterEditorEditingDone(changed: Bool)
}
