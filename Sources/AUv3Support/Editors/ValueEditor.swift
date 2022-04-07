// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit
import os.log
import AudioToolbox

/**
 Manages editing of an AUParameter float value. There is no need to have more than one of these instances since editing
 can only take place on one parameter at a time.
 */
public class ValueEditor: NSObject {
  private let log = Shared.logger("ValueEditor")

  private let containerView: UIView
  private let backgroundView: UIView
  private let parameterName: UILabel
  private let parameterValueEditor: UITextField
  private let containerViewTopConstraint: NSLayoutConstraint
  private let backgroundViewBottomConstraint: NSLayoutConstraint
  private let controlsView: UIView
  private let parent: UIView

  private var editing: AUParameterEditor?
  private var keyboardIsVisible = false

  public init(containerView: UIView, backgroundView: UIView, parameterName: UILabel, parameterValue: UITextField,
              containerViewTopConstraint: NSLayoutConstraint, backgroundViewBottomConstraint: NSLayoutConstraint,
              controlsView: UIView) {
    os_log(.info, log: log, "init BEGIN")

    self.containerView = containerView
    self.backgroundView = backgroundView
    self.parameterName = parameterName
    self.parameterValueEditor = parameterValue
    self.containerViewTopConstraint = containerViewTopConstraint
    self.backgroundViewBottomConstraint = backgroundViewBottomConstraint
    self.controlsView = controlsView
    self.parent = containerView.superview!
    super.init()

    containerViewTopConstraint.constant = 0
    backgroundViewBottomConstraint.constant = 0

    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardAppearing(_:)),
                                           name: UIApplication.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChanged(_:)),
                                           name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDisappearing(_:)),
                                           name: UIApplication.keyboardWillHideNotification, object: nil)

    backgroundView.layer.cornerRadius = 8.0
    containerView.isHidden = true

    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    containerView.addGestureRecognizer(gestureRecognizer)
    os_log(.info, log: log, "init END - %{public}s", self.pointer)
  }
}

extension ValueEditor {

  /**
   Start editing a value.

   - parameter editor: the parameter editor that manages the AUParameter value.
   */
  public func beginEditing(editor: AUParameterEditor) {
    os_log(.info, log: log, "beginEditing - %d", editor.parameter.address)

    editing = editor

    parameterName.text = editor.parameter.displayName
    parameterValueEditor.text = "\(editor.parameter.value)"
    parameterValueEditor.becomeFirstResponder()
    parameterValueEditor.delegate = self

    containerView.alpha = 1.0
    containerView.isHidden = false
  }

  /**
   Stop editing. Normally, calling this is not necessary as it should be done automatically by this editor.

   - parameter accept: if true, accept whatever value is currently being held and try to store it into the parameter.
   */
  public func endEditing(accept: Bool = true) {
    guard let editor = editing else { fatalError() }
    os_log(.info, log: log, "endEditing BEGIN - address: %d", editor.parameter.address)

    if accept,
       let stringValue = parameterValueEditor.text,
       let value = AUValue(stringValue),
       value != editor.parameter.value {
      editing?.setValue(value)
    }

    editing = nil
    parameterValueEditor.resignFirstResponder()

    os_log(.info, log: log, "endEditing END")
  }
}

// MARK: - Keyboard tracking

private extension ValueEditor {

  @objc func handleKeyboardAppearing(_ notification: Notification) {
    os_log(.info, log: log, "handleKeyboardAppearing BEGIN")
    let keyboardInfo = KeyboardInfo(notification)
    os_log(.info, log: log, "handleKeyboardAppearing - info: %{public}s", keyboardInfo.description)

    let height = keyboardInfo.frameEnd.height
    backgroundViewBottomConstraint.constant = -backgroundView.frame.height
    parent.layoutIfNeeded()

    keyboardIsVisible = height >= 100
    let goal = keyboardIsVisible ? height + 20 : parent.frame.midY

    os_log(.info, log: log, "handleKeyboardAppearing END - goal: %f keyboardIsVisible: %d", goal, keyboardIsVisible)
    animateWithKeyboard(keyboardInfo) { _ in
      self.backgroundViewBottomConstraint.constant = goal
      self.parent.layoutIfNeeded()
      self.controlsView.alpha = 0.40
    }
  }

  @objc private func handleKeyboardChanged(_ notification: Notification) {
    os_log(.info, log: log, "handleKeyboardChanged BEGIN")
    let keyboardInfo = KeyboardInfo(notification)
    os_log(.info, log: log, "handleKeyboardChanged - info: %{public}s", keyboardInfo.description)
  }

  @objc private func handleKeyboardDisappearing(_ notification: Notification) {
    os_log(.info, log: log, "handleKeyboardDisappearing BEGIN - editing: %d", editing != nil ? 1 : 0)
    let keyboardInfo = KeyboardInfo(notification)
    os_log(.info, log: log, "handleKeyboardDisappearing - info: %{public}s", keyboardInfo.description)

    parent.layoutIfNeeded()
    keyboardIsVisible = false

    let doneEditing = editing == nil
    let goal = doneEditing ? -backgroundView.frame.height : parent.frame.midY

    animateWithKeyboard(keyboardInfo) { _ in
      self.backgroundViewBottomConstraint.constant = goal
      if doneEditing {
        self.controlsView.alpha = 1.0
      }
    } completion: { _ in
      self.containerView.isHidden = doneEditing
    }
  }

  @objc func handleTap(_ sender: UITapGestureRecognizer) {
    endEditing()
  }

  func animateWithKeyboard(_ keyboardInfo: KeyboardInfo, animations: @escaping (_ keyboardFrame: CGRect) -> Void,
                           completion: ((UIViewAnimatingPosition) -> Void)? = nil) {
    let animator = UIViewPropertyAnimator(duration: keyboardInfo.animationDuration, curve: keyboardInfo.animationCurve)
    animator.addAnimations {
      animations(keyboardInfo.frameEnd)
      self.parent.layoutIfNeeded()
    }

    if let completion = completion {
      animator.addCompletion(completion)
    }

    os_log(.info, log: log, "animateWithKeyboard - starting")
    animator.startAnimation()
  }
}

extension ValueEditor: UITextFieldDelegate {

  /**
   Detect when user touches/presses RETURN on the keyboard. Stops editing as a side-effect.

   - parameter textField: the text field currently being edited (ignored)
   - returns: always false
   */
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    os_log(.info, log: log, "textFieldShouldReturn BEGIN")
    endEditing()
    os_log(.info, log: log, "textFieldShouldReturn END")
    return false
  }

  /**
   Detect when user stops editing the value. Stops editing as a side-effect if the editing text field is the currently
   active responder. Note that this will always get called when `endEditing` runs -- it is here for those times when
   something else grabs the first responder.

   - parameter textField: the text field current being edited (ignored)
   */
  public func textFieldDidEndEditing(_ textField: UITextField) {
    os_log(.info, log: log, "textFieldDidEndEditing BEGIN")
    if textField.isFirstResponder {
      endEditing(accept: false)
    }
    os_log(.info, log: log, "textFieldDidEndEditing END")
  }
}

fileprivate struct KeyboardInfo {
  let animationCurve: UIView.AnimationCurve
  let animationDuration: Double
  let isLocal: Bool
  let frameBegin: CGRect
  let frameEnd: CGRect

  init(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      (notification.name == UIResponder.keyboardWillShowNotification ||
       notification.name == UIResponder.keyboardWillHideNotification ||
       notification.name == UIResponder.keyboardWillChangeFrameNotification)
    else {
      fatalError("unexpected notification type")
    }

    let animationCurve = userInfo[UIWindow.keyboardAnimationCurveUserInfoKey] as! Int
    let animationDuration = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as! Double
    let isLocal = userInfo[UIWindow.keyboardIsLocalUserInfoKey] as! Bool
    let frameBegin = userInfo[UIWindow.keyboardFrameBeginUserInfoKey] as! CGRect
    let frameEnd = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as! CGRect

    self.animationCurve = UIView.AnimationCurve(rawValue: animationCurve)!
    self.animationDuration = animationDuration
    self.isLocal = isLocal
    self.frameBegin = frameBegin
    self.frameEnd = frameEnd
  }
}

extension KeyboardInfo: CustomStringConvertible {
  var description: String {
    "<KeyboardInfo: curve: \(animationCurve.rawValue) duration: \(animationDuration) height: \(frameEnd.height)>"
  }
}

#endif
