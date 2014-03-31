//
//  PizzaPlaceAnnotation.h
//  LazyPizzaFinder
//
//  Created by Marion Ano on 3/27/14.
//  Copyright (c) 2014 Marion Ano. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface PizzaPlaceAnnotation : MKPointAnnotation
@property NSDictionary *pizzaPlaceArrray;
@property CLLocationCoordinate2D coordinate;
@end
