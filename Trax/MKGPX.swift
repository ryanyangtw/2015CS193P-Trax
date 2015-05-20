//
//  MKGPX.swift
//  Trax
//
//  Created by Ryan on 2015/5/20.
//  Copyright (c) 2015年 Ryan. All rights reserved.
//

import MapKit

extension GPX.Waypoint: MKAnnotation {


  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  var title: String! { return name }
  
  var subtitle: String! { return info }
  
  var thumbnailURL: NSURL? { return getImageURLofType("thumbnail") }
  var imageURL: NSURL? { return getImageURLofType("large") }

  private func getImageURLofType(type: String) -> NSURL? {
    for link in links {
      if link.type == type {
        return link.url
      }
    }
    
    return nil
  }

}
