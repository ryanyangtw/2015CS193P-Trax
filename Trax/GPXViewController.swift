//
//  ViewController.swift
//  Trax
//
//  Created by Ryan on 2015/5/19.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate {

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
  
  
  // MARK: Constants
  
  private struct Constants {
    static let PartialTrackColor = UIColor.greenColor()
    static let FullTrackColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
    static let TrackLineWidth: CGFloat = 3.0
    static let ZoomCooldown = 1.5
    static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
    static let AnnotationViewReuseIdentifier = "waypoint"
    static let ShowImageSegue = "Show Image"
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
    
    view.leftCalloutAccessoryView = nil
    view.rightCalloutAccessoryView = nil
    
    if let waypoint = annotation as? GPX.Waypoint {
      if waypoint.thumbnailURL != nil {
        view.leftCalloutAccessoryView = UIImageView(frame: Constants.LeftCalloutFrame)
      }
      
      if waypoint.imageURL != nil {
        // buttonWithType return AnyObject
        view.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
      }
    }
    
    
    return view
  }
  
  
  func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
    
    if let waypoint = view.annotation as? GPX.Waypoint {
      if let thumbnailImageView = view.leftCalloutAccessoryView as? UIImageView {
        if let imageData = NSData(contentsOfURL: waypoint.thumbnailURL!) {
          // blocks main thread!
          if let image = UIImage(data: imageData) {
            thumbnailImageView.image = image
          }
        }
      }
    }
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
  }
  
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == Constants.ShowImageSegue {
      if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
        if let ivc = segue.destinationViewController as? ImageViewController {
          ivc.imageURL = waypoint.imageURL
          ivc.title = waypoint.name
        }
      }
    }
  }
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    
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
    
    gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

