// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit
import os.log
import AudioToolbox

/**
 Manages editing of an AUParameter float value. There is no need to have more than one of these instances since editing
 can only take place on one parameter at a time.
 */
@MainActor
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
  }
}

extension ValueEditor {

  /**
   Start editing a value.

   - parameter editor: the parameter editor that manages the AUParameter value.
   */
  public func beginEditing(editor: AUParameterEditor, editingValue: String) {
    editing = editor
    parameterName.text = editor.parameter.displayName
    parameterValueEditor.text = editingValue
    parameterValueEditor.becomeFirstResponder()
    parameterValueEditor.delegate = self
    containerView.alpha = 1.0
    containerView.isHidden = false
    parameterValueEditor.selectAll(nil)
  }

  /**
   Stop editing. Normally, calling this is not necessary as it should be done automatically by this editor.
   */
  public func endEditing() {
    guard let editor = editing else { fatalError() }

    if let stringValue = parameterValueEditor.text, let value = AUValue(stringValue), value != editor.parameter.value {
      editor.setValue(value)
      editor.delegate?.parameterEditorEditingDone(changed: true)
    }
    else {
      editor.delegate?.parameterEditorEditingDone(changed: false)
    }

    editing = nil
    parameterValueEditor.resignFirstResponder()
  }
}

// MARK: - Keyboard tracking

private extension ValueEditor {

  @objc func handleKeyboardAppearing(_ notification: Notification) {
    let keyboardInfo = KeyboardInfo(notification)
    let height = keyboardInfo.frameEnd.height
    backgroundViewBottomConstraint.constant = -backgroundView.frame.height
    parent.layoutIfNeeded()

    keyboardIsVisible = height >= 100
    let goal = keyboardIsVisible ? height + 20 : parent.frame.midY

    animateWithKeyboard(keyboardInfo) { _ in
      self.backgroundViewBottomConstraint.constant = goal
      self.parent.layoutIfNeeded()
      self.controlsView.alpha = 0.40
    }
  }

  @objc private func handleKeyboardChanged(_ notification: Notification) {}

  @objc private func handleKeyboardDisappearing(_ notification: Notification) {
    let keyboardInfo = KeyboardInfo(notification)
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
    endEditing()
    return false
  }

  /**
   Detect when user stops editing the value. Stops editing as a side-effect if the editing text field is the currently
   active responder. Note that this will always get called when `endEditing` runs -- it is here for those times when
   something else grabs the first responder.

   - parameter textField: the text field current being edited (ignored)
   */
  public func textFieldDidEndEditing(_ textField: UITextField) {
    if textField.isFirstResponder {
      endEditing()
    }
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
