//
//  ViewController.swift
//  Trax
//
//  Created by Ryan on 2015/5/19.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var textView: UITextView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    
    let center = NSNotificationCenter.defaultCenter()
    let queue = NSOperationQueue.mainQueue()
    let appDelefate = UIApplication.sharedApplication().delegate
    
    center.addObserverForName( GPXURL.Notification , object: appDelefate, queue: queue) {
      notification in 
      
      if let url = notification?.userInfo?[GPXURL.Key] as? NSURL {
        self.textView.text = "Received \(url)"
      }
    }
    
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

