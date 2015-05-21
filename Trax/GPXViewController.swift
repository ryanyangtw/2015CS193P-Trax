//
//  ViewController.swift
//  Trax
//
//  Created by Ryan on 2015/5/19.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {

  //@IBOutlet weak var textView: UITextView!
  
  
  // MARK: - Outlets
  
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
      mapView.mapType = .Satellite
      mapView.delegate = self
    }
  }
  
  // MARK: - Public API
  
  var gpxURL: NSURL? {
    didSet {
      clearWaypoints()
      if let url = gpxURL {
        GPX.parse(url) {
          if let gpx = $0 {
            self.handleWaypoints(gpx.waypoints)
          }
        }
      }
    }
  }
  
  private func clearWaypoints() {
    if mapView?.annotations != nil { mapView.removeAnnotations(mapView.annotations as? [MKAnnotation])}
  }
  
  private func handleWaypoints(waypoints: [GPX.Waypoint]) {
    mapView.addAnnotations(waypoints)
    mapView.showAnnotations(waypoints, animated: true)
  }
  
  @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
    
    if sender.state == UIGestureRecognizerState.Began {
      let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
      let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
      
      waypoint.name = "Dropped"
      mapView.addAnnotation(waypoint)
      
    }
  }

  
  // MARK: Constants
  
  private struct Constants {
    static let PartialTrackColor = UIColor.greenColor()
    static let FullTrackColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
    static let TrackLineWidth: CGFloat = 3.0
    static let ZoomCooldown = 1.5
    static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
    static let AnnotationViewReuseIdentifier = "waypoint"
    static let ShowImageSegue = "Show Image"
    
    static let EditWaypointSegue = "Edit Waypoint"
    static let EditWaypointPopoverWidth: CGFloat = 320
  }
  
  
  // MARK: - MKMapViewDelegate
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {

    var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
    
    if view == nil {
      view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
      view.canShowCallout = true
    } else {
      view.annotation = annotation
    }
    
    

    view.draggable = annotation is EditableWaypoint
    
    view.leftCalloutAccessoryView = nil
    view.rightCalloutAccessoryView = nil
    
    if let waypoint = annotation as? GPX.Waypoint {
      if waypoint.thumbnailURL != nil {
        view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
      }
      
      //if waypoint.imageURL != nil {
      if annotation is EditableWaypoint {
        // buttonWithType return AnyObject
        view.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
      }
      //}
    }
    
    
    return view
  }
  
  
  func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
    
    if let waypoint = view.annotation as? GPX.Waypoint {
      if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
        if let imageData = NSData(contentsOfURL: waypoint.thumbnailURL!) {
          // blocks main thread!
          if let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, forState: .Normal)
          }
        }
      }
    }
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    
    if (control as? UIButton)?.buttonType == UIButtonType.DetailDisclosure {
      mapView.deselectAnnotation(view.annotation, animated: false)
      performSegueWithIdentifier(Constants.EditWaypointSegue, sender: view)
      
    } else if let waypoint = view.annotation as? GPX.Waypoint {
      if waypoint.imageURL != nil {
        performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
      }
    }
    
  }
  
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == Constants.ShowImageSegue {
      if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
        if let ivc = segue.destinationViewController.contentViewController as? ImageViewController {
          ivc.imageURL = waypoint.imageURL
          ivc.title = waypoint.name
        }
      }
    } else if segue.identifier == Constants.EditWaypointSegue {
      if let waypoint = (sender as? MKAnnotationView)?.annotation as? EditableWaypoint {
        if let ewvc = segue.destinationViewController.contentViewController as? EditWaypointViewController {
          
          if let ppc = ewvc.popoverPresentationController {
            let coordinatePoint = mapView.convertCoordinate(waypoint.coordinate, toPointToView: mapView)
            // Please give me a rectangle that would be good for a popover to point at.
            ppc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForCoordinatePoint(coordinatePoint)
            // As small as it can
            let minimumSize = ewvc.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            ewvc.preferredContentSize = CGSize(width: Constants.EditWaypointPopoverWidth, height: minimumSize.height)
            
            ppc.delegate = self
            
          }
          
    
          ewvc.waypointToEdit = waypoint
        }
      }
    }
  }
  
  
  // MARK: - UIAdaptivePresentationControllerDelegate
  
  
  // If the devise is iphone, it will trigger the delegates below
  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
    return UIModalPresentationStyle.OverFullScreen // full screen, but we can see what's underneath
  }
  
  // Give me a view controller to display this thing when I adapt
  // I am going to give it a navigation controller, and tell it to use that instead
  func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
    let navcon = UINavigationController(rootViewController: controller.presentedViewController)
    
    // It's a visual effect view. and that view looks what's behinds it and blurs it and draws that as itself
    // Put a visual effects view right at the top of the navigation controller's view hierarchy. behind everything that it draws. We just put it at index zero in the subviews list.
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
    visualEffectView.frame = navcon.view.bounds
    navcon.view.insertSubview(visualEffectView, atIndex: 0) // "back-most" subview
    
    return navcon
  }
  
  
  // MARK: - View Controller Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // sign up to hear about GPX files arriving
    // we never remove this observer, so we will never leave the heap
    // might make some sense to think about when to remove this observer
    
    let center = NSNotificationCenter.defaultCenter()
    let queue = NSOperationQueue.mainQueue()
    let appDelefate = UIApplication.sharedApplication().delegate
    
    center.addObserverForName( GPXURL.Notification , object: appDelefate, queue: queue) {
      notification in 
      
      if let url = notification?.userInfo?[GPXURL.Key] as? NSURL {
        //self.textView.text = "Received \(url)"
        self.gpxURL = url
        
      }
    
    }
    
    gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx") // for demo/debug/testing

    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}



// MARK - Convenience Extensions

extension UIViewController {
  var contentViewController: UIViewController {
    if let navcon = self as? UINavigationController {
      return navcon.visibleViewController
    } else {
      return self
    }
  }
}

extension MKAnnotationView {

  func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
    var popoverSourceRectCenter = coordinatePoint
    popoverSourceRectCenter = coordinatePoint
    popoverSourceRectCenter.x -= frame.width / 2 - centerOffset.x - calloutOffset.x
    popoverSourceRectCenter.y -= frame.height / 2 - centerOffset.y - calloutOffset.y
    
    return CGRect(origin: popoverSourceRectCenter, size: frame.size)
  }
}




