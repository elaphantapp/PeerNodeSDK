//
//  RadioGroupView.swift
//  test
//
//  Created by mengxk on 2019/10/8.
//  Copyright © 2019 Elastos. All rights reserved.
//

import Foundation
import UIKit

open class RadioGroupView: UIStackView {
  public typealias OnClickedClosure = (_ index: Int, _ button: UISwitch) -> ()

  open func addRadioButtons(titles: [String], selected: Int = -1) {
    for idx in titles.indices {
      addRadioButton(title: titles[idx], selected: idx == selected)
    }
  }
  
  open func addRadioButton(title: String, selected: Bool = false) {
    let radioView = UIStackView()
    
    let radioBtn = UISwitch()
    radioBtn.addTargetClosure(closure: onClicked)
    radioView.addArrangedSubview(radioBtn)
  
    let radioLabel = UILabel()
    radioLabel.text = title
    radioLabel.translatesAutoresizingMaskIntoConstraints = false
    radioLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
    radioView.addArrangedSubview(radioLabel)
  
    self.addArrangedSubview(radioView)
    
    if selected == true {
      radioBtn.sendActions(for: .touchUpInside)
    }
  }
  
  public func setOnClickedClosure(closure: OnClickedClosure?) {
    self.onClickedClosure = closure
  }

  var selectedButton: UISwitch?
  
  var selectedTitle: String? {
    return (selectedButton?.superview?.subviews.last as? UILabel)?.text
  }
  
  var selectedIndex: Int {
    guard selectedButton != nil else {
      return -1
    }
    return self.arrangedSubviews.firstIndex(of: selectedButton!.superview!) ?? -1
  }

  private func onClicked(sender: UIControl) {
    selectedButton?.setOn(false, animated: false)
    selectedButton = sender as? UISwitch
    selectedButton?.setOn(true, animated: false)
    
    onClickedClosure?(selectedIndex, sender as! UISwitch)
  }
  
  private var onClickedClosure: OnClickedClosure?
}

extension UIControl {
  public typealias TargetClosure = (UIControl) -> ()

  func addTargetClosure(closure: @escaping TargetClosure) {
    targetClosure = closure
    addTarget(self, action: #selector(UIControl.closureAction), for: .touchUpInside)
  }
  @objc func closureAction() {
      guard let targetClosure = targetClosure else { return }
      targetClosure(self)
  }
  
  private struct AssociatedKeys {
      static var targetClosure = "targetClosure"
  }
  
  private var targetClosure: TargetClosure? {
      get {
          guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.targetClosure) as? ClosureWrapper else { return nil }
          return closureWrapper.closure
      }
      set(newValue) {
          guard let newValue = newValue else { return }
          objc_setAssociatedObject(self, &AssociatedKeys.targetClosure, ClosureWrapper(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
  }
  
  class ClosureWrapper: NSObject {
      let closure: TargetClosure
      init(_ closure: @escaping TargetClosure) {
          self.closure = closure
      }
  }
}
