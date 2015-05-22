//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Ryan on 2015/5/21.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditWaypointViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  
  // MARK: - Public API
  
  var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }


  
  
  // MARK: - Private Implementation
  
  private func updateUI() {
    nameTextField?.text = waypointToEdit?.name
    infoTextField?.text = waypointToEdit?.info
    updateImage()
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
  
  
  // MARK: - Image
  
  var imageView = UIImageView()
  @IBOutlet weak var imageViewContainer: UIView! {
    didSet {
      // we put a generic UIView in our autolayout
      // because it will shrink and grow as the space allows
      // (versus a UIImageView which demands space to show its image)
      // we will manage the frame of the image view ourself
      // (in makeRoomForImage() below)
      imageViewContainer.addSubview(imageView)
    }
  }
  
  @IBAction func takePhoto() {
    
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      let picker = UIImagePickerController()
      picker.sourceType = .Camera
      
      // if we were looking for video, we'd check availableMediaTypes
      picker.mediaTypes = [kUTTypeImage]
      picker.delegate = self
      picker.allowsEditing = true
      presentViewController(picker, animated: true, completion: nil)
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    var image = info[UIImagePickerControllerEditedImage] as? UIImage
    if image == nil {
      image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    imageView.image = image
    makeRoomForImage()
    saveImageInWaypoint()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  // we save the image in the file system here, but we never remove it
  // obviously this demo is only the start of this application
  // not only would we need to manage the images in our filesystem
  // but we don't even save our edited waypoints from app launch to app launch
  // (we'd probably want to be able to write these edited waypoints to a gpx file too)
  // the goal here is just to show how to access the file system
  
  func saveImageInWaypoint()
  {
    if let image = imageView.image {
      println("has image")
      if let imageData = UIImageJPEGRepresentation(image, 1.0) {
        println("imageData ok")
        let fileManager = NSFileManager()
        if let docsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as? NSURL {
          
          println("docsDir ok")
          let unique = NSDate.timeIntervalSinceReferenceDate()
          let url = docsDir.URLByAppendingPathComponent("\(unique).jpg")
          if let path = url.absoluteString {
            println("path: \(path)")
            if imageData.writeToURL(url, atomically: true) {
              waypointToEdit?.links = [GPX.Link(href: path)]
            }
          }
        }
      }
      
    }
  }
  
  // 0 means the most compressed you can do. 1 means almost no compression.
  
  
  
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


extension EditWaypointViewController {

  func updateImage() {
    if let url = waypointToEdit?.imageURL {
      let qos = Int(QOS_CLASS_USER_INITIATED.value)
      dispatch_async(dispatch_get_global_queue(qos, 0)) {
        [weak self] in
        
        if let imageData = NSData(contentsOfURL: url) {
          
          // 確認抓回來的圖是原本打算顯示的圖
          if url == self?.waypointToEdit?.imageURL {
            if let image = UIImage(data: imageData) {
              dispatch_async(dispatch_get_main_queue()) {
                self?.imageView.image = image
                self?.makeRoomForImage()
              }
            }
          }
        }
      }
    }
  }
  

  // all we do in makeRoomForImage() is adjust our preferredContentSize
  // we assume that our preferredContentSize is what is currently desired (pre-adjustment)
  // then we adjust it to make up for any differences in the size of our image view or its container
  // if our preferredContentSize change can be accomodated, our container will get taller
  // and more of our image will show
  // if not, we tried our best to show as much of the image as possible
  // because we use the entire width of our container view and
  // show an appropriate height depending on our image's aspect ratio
  // this is sort of a "quick and dirty" way to do this
  // in a real application, one would probably want to be more exacting here
  // (perhaps apply more sophisticated autolayout to the problem)
  
  func makeRoomForImage() {
    var extraHeight: CGFloat = 0
    if imageView.image?.aspectRatio > 0 {
      if let width = imageView.superview?.frame.size.width {
        let height = width / imageView.image!.aspectRatio
        extraHeight = height - imageView.frame.height
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
      }
    } else {
      extraHeight = -imageView.frame.height
      imageView.frame = CGRectZero
    }
    
    preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
  }
  

}

extension UIImage {
  var aspectRatio: CGFloat {
    return size.height != 0 ? size.width / size.height : 0
  }
}
