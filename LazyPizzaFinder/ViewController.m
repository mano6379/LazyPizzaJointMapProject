//
//  ViewController.m
//  LazyPizzaFinder
//
//  Created by Marion Ano on 3/26/14.
//  Copyright (c) 2014 Marion Ano. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PizzaPlaceAnnotation.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate>
{
    
    IBOutlet UITableView *myTableView;
    IBOutlet MKMapView *myView;
    NSArray *pizzaPlaces;
    double timeToVisitAllShops;
}
@property CLLocationManager *locationManager;
//@property MKPinAnnotationView *pizzaPlacesAnnotation;
@end

@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    myView.showsUserLocation = YES;
    
    
    //self.pizzaPlacesAnnotation = [MKPinAnnotationView new];
    
    
    timeToVisitAllShops = 9000;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    pizzaPlaces = [NSMutableArray new];
    
    for (NSArray *places in pizzaPlaces)
    
    {
        
        PizzaPlaceAnnotation *annotation = [PizzaPlaceAnnotation new];
        
        
        //annotation.coordinate = MKMapItem.placem
        
        
        
        
        //[myView addAnnotation:annotation];
    }
    
    //code I just added from GetOnBus Project
    
//    NSArray *pizzaPlaces = myMapDictionary[@"row"];
//    NSLog(@"%@", myTransitStops);
//    
//    for (NSDictionary *stop in myTransitStops)
//    {
//        double latitude = [stop[@"latitude"]doubleValue];
//        double longitude = [stop[@"longitude"]doubleValue];
//        
//        CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
//        BusStopAnnotation *annotation = [BusStopAnnotation new];
//        annotation.coordinate = centerCoordinate;
//        annotation.busStopDictionary = stop;
//        
//        annotation.title = stop[@"cta_stop_name"];
//        annotation.subtitle = stop[@"routes"];
//        NSLog(@"Title %@", annotation.title);
//        [self.myMapView addAnnotation:annotation];
//    }
//    
//    
//    CLLocationCoordinate2D averageCoordinate = CLLocationCoordinate2DMake(0, 0);
//    
//    for (NSDictionary *stop in myTransitStops)
//    {
//        double lat = [stop[@"latitude"] doubleValue];
//        double lng = [stop[@"longitude"] doubleValue];
//        
//        averageCoordinate.latitude += lat;
//        averageCoordinate.longitude += lng;
//    }
//    
//    averageCoordinate.latitude /= myTransitStops.count;
//    averageCoordinate.longitude /= myTransitStops.count;
//    
//    MKCoordinateSpan coordinateSpan = MKCoordinateSpanMake(0.4, 1.0);
//    MKCoordinateRegion region = MKCoordinateRegionMake(averageCoordinate, coordinateSpan);
//    self.myMapView.region = region;
//    
//}];
//

}

- (void)didReceiveMemoryWarning{
    
    [super didReceiveMemoryWarning];

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return pizzaPlaces.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PizzaCellReuseID"];
    MKMapItem* pizzaPlace = pizzaPlaces[indexPath.row];
    cell.textLabel.text = pizzaPlace.name;
    int distance = roundf([pizzaPlace.placemark.location distanceFromLocation:self.locationManager.location]);
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Crow's Distance: %i meters", distance];
    
    return cell;

}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    
    NSString* string;
    if ((int)round(timeToVisitAllShops) == 9000) {
        string = @"Estimated time is: Calculating";
    }
    else{
        string = [NSString stringWithFormat:@"Estimated time is: %d minutes", ((int)round(timeToVisitAllShops)/60)];
    }
    return string;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    for (CLLocation *location in locations){
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000){
            [self startReverseGeocode:location];
            [self.locationManager stopUpdatingLocation];
            break;
        }
    }
}

-(void) startReverseGeocode: (CLLocation *) location{
    
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        [self askAppleForPizza:placemarks.firstObject];
            
    }];
}

-(void) askAppleForPizza: (CLPlacemark*) placemark{
    
    MKLocalSearchRequest* request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(placemark.location.coordinate, MKCoordinateSpanMake(1,1));
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        
        NSArray *mapItems = response.mapItems;
        mapItems = [mapItems sortedArrayUsingComparator:^NSComparisonResult(MKMapItem* obj1, MKMapItem* obj2) {
            float d1 = [obj1.placemark.location distanceFromLocation:self.locationManager.location];
            float d2 = [obj2.placemark.location distanceFromLocation:self.locationManager.location];
            if (d1 < d2)
            {
                return NSOrderedAscending;
            }
            else
            {
                return NSOrderedDescending;
            }
        }];

        NSRange numberOfAvaiblePizzaPlaces;
        if (mapItems.count >= 4)
        {
            numberOfAvaiblePizzaPlaces = NSMakeRange(0, 4);
            mapItems = [mapItems subarrayWithRange:numberOfAvaiblePizzaPlaces];
        }
        else
        {
            numberOfAvaiblePizzaPlaces = NSMakeRange(0, mapItems.count);
            mapItems = [mapItems subarrayWithRange:numberOfAvaiblePizzaPlaces];
        }

        pizzaPlaces = mapItems;
        [self calculateDistance:mapItems];
        [myTableView reloadData];
    }];
}

-(void) calculateDistance:(NSArray *) nextDestinaton{
    
    MKDirectionsRequest* request = [MKDirectionsRequest new];
    request.transportType = MKDirectionsTransportTypeWalking;
    
    for (int i = 0; i<nextDestinaton.count; i++) {
        if (i == 0) {
        request.source = [MKMapItem mapItemForCurrentLocation];
        }else{
        request.source = [nextDestinaton objectAtIndex:i-1];
        }
        request.destination = [nextDestinaton objectAtIndex:i];
        MKDirections* directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            MKRoute* route = response.routes.firstObject;
            timeToVisitAllShops += route.expectedTravelTime;
            [myTableView reloadData];
            
        }];
    }
}
//CLLocation Class
//measure distance between coordinates
//[ -distanceFromLocation: (starting location)];


//NSArray
//sort array from smallest to biggest
//[ -sortedArrayUsingComparator: (NSComparator)comparator];

//NSComparator
//NSArray *sortedArray = [array sortedArrayUsingComparator: ^(id obj1, id obj2)
//{
//  if ([obj1 integerValue] < [obj2 intergerValue])
//{
//    return (NSComparisonResult)NSOrderedAscending;
//}
//return (NSComparisonResult)NSOrderedSame;
//}
@end
