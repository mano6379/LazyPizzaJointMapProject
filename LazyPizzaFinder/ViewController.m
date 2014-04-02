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
@end

@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    myView.showsUserLocation = YES;
    
    
    //self.pizzaPlacesAnnotation = [MKPinAnnotationView new];
    
    
    timeToVisitAllShops = 9000;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    myView.delegate = self;
    [self.locationManager startUpdatingLocation];
    pizzaPlaces = [NSMutableArray new];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == mapView.userLocation)
    {
        return nil;
    }
    
    // Set pin image attributes
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:nil];
    //pin.image = [UIImage imageNamed:@"Chicago-1"];
    pin.canShowCallout = YES;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return pin;
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
        //everything in the array goes in as an id object
        for (MKMapItem *place in pizzaPlaces)
        {
            //create a new annotation object
            //CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude,longitude);
            MKPointAnnotation *annotation = [MKPointAnnotation new];
            annotation.coordinate = place.placemark.location.coordinate;
            //make an array of annotations
            [myView addAnnotation:annotation];
            
        }
        [myView reloadInputViews];
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
