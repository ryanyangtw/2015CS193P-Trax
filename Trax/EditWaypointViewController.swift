//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Ryan on 2015/5/21.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import UIKit

class EditWaypointViewController: UIViewController, UITextFieldDelegate {
  
  
  // MARK: - Public API
  
  var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }


  
  
  // MARK: - Private Implementation
  
  private func updateUI() {
    nameTextField?.text = waypointToEdit?.name
    infoTextField?.text = waypointToEdit?.info
  }
  
  @IBAction func done(sender: UIBarButtonItem) {
    // If my presenting view controller has presented me and I've presented someone else, when I do this dismiss, it's going to dismiss all of us
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  

  
  // MARK: - View Controller Lifecycle
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    startObservingTextFields()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    stopObservingTextFields()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    nameTextField.becomeFirstResponder()
    updateUI()

  }
  
  
  // MARK: - Text Fields
  
  @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
  @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  private var ntfObserver: NSObjectProtocol?
  private var itfObserver: NSObjectProtocol?
  
  private func startObservingTextFields()
  {
    let center = NSNotificationCenter.defaultCenter()
    let queue = NSOperationQueue.mainQueue()
    ntfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: nameTextField, queue: queue) { notification in
      if let waypoint = self.waypointToEdit {
        waypoint.name = self.nameTextField.text
      }
    }
    itfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: infoTextField, queue: queue) { notification in
      if let waypoint = self.waypointToEdit {
        waypoint.info = self.infoTextField.text
      }
    }
  }
  
  private func stopObservingTextFields()
  {
    if let observer = ntfObserver {
      NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    if let observer = itfObserver {
      NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
  }
  
  

  

}
