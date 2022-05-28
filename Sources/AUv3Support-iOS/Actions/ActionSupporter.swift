// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

/**
 Functionality required to support preset editing actions. Broken out here to remove dependency on UIViewController.
 */
public protocol ActionSupporter: AnyObject {

  /**
   Ask the user for a name for a preset. Used to create a new preset or rename an existing one.

   - parameter title: the title of the ask
   - parameter placeholder: the value to use as a placeholder
   - parameter activity: the activity that will be performed (eg "Create" or "Rename") if not cancelled.
   Used for the non-cancel button title.
   - parameter closure: closure to run if not cancelled *and* the resulting string has some value besides spaces
   */
  func askForName(title: String, placeholder: String, activity: String, _ closure: @escaping (String) -> Void)

  /**
   Confirm continuing with a destructive activity.

   - parameter title: the title of the confirmation
   - parameter message: the message to show
   - parameter closure: the closure to run if confirmed
   */
  func confirmAction(title: String, message: String, _ closure: @escaping () -> Void)

  /**
   Notify the user that there was a problem executing a preset change. This would come from an exception thrown by the
   AUAudioUnit routines.

   - parameter title: the title of the error
   - parameter message: the contents of the error
   */
  func notifyFailure(title: String, message: String)

  /**
   Function to call when all activity for an action is done. This will only be called upon successful completion. Any
   activity flow that did not end in a preset change will not call this.
   */
  func completeAction()
}

#endif
