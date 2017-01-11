//
//  MapVC.m
//  GoogleMapsRouting
//
//  Created by YAUHENI DROBAU on 11/01/2017.
//  Copyright © 2017 YAUHENI DROBAU. All rights reserved.
//

#import "MapVC.h"
#import <CoreLocation/CoreLocation.h>

@import GoogleMaps;

#define BLUE_COLOR [UIColor colorWithRed:28. / 255. green:195. / 255. blue:244. / 255 alpha:1.0]
#define POINTS_STEPS 5

@interface MapVC ()

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) NSArray *points;
@property (strong, nonatomic) NSMutableArray *coordinatesArray;

@end

@implementation MapVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.points = @[[NSValue valueWithCGPoint:CGPointMake(-31.866, 51.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-32.866, 52.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-33.866, 53.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-24.866, -48.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-25.866, 55.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-36.866, 56.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-37.866, 57.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-38.866, -58.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-39.866, 59.195)],
                    [NSValue valueWithCGPoint:CGPointMake(-40.866, 60.195)]];
    self.coordinatesArray = [[NSMutableArray alloc]init];
    
    CGPoint firstPoint = ((NSValue *)_points.firstObject).CGPointValue;
    CGPoint lastPoint = ((NSValue *)_points.lastObject).CGPointValue;
    CLLocationDegrees startLatitudeDeg = firstPoint.x;
    CLLocationDegrees startLongitudeDeg = firstPoint.y;
    CLLocationDegrees endLatitudeDeg = lastPoint.x;
    CLLocationDegrees endLongitudeDeg = lastPoint.y;
    
    CLLocationCoordinate2D startPosition = CLLocationCoordinate2DMake(startLatitudeDeg, startLongitudeDeg);
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-43.866
                                longitude:58.195
                                     zoom:2
                                  bearing:30
                             viewingAngle:40];
    self.mapView.camera = camera;
    GMSMutablePath *path = [GMSMutablePath path];
    
    CGPathRef yourCGPath = [self quadCurvedPathWithPoints:self.points].CGPath;
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void * _Nullable)(bezierPoints), MyCGPathApplierFunc);
    
    for (NSValue *point in bezierPoints) {
        CGPoint mapPoint = point.CGPointValue;
        [path addCoordinate:CLLocationCoordinate2DMake(mapPoint.x, mapPoint.y)];
    }
    GMSMarker *startMarker = [GMSMarker markerWithPosition:startPosition];
    startMarker.title = @"Start";
    startMarker.icon = [UIImage imageNamed:@"start"];
    startMarker.map = _mapView;
    
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(endLatitudeDeg, endLongitudeDeg);
    GMSMarker *london = [GMSMarker markerWithPosition:position];
    london.title = @"End";
    london.icon = [UIImage imageNamed:@"end"];
    london.map = _mapView;
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeColor = BLUE_COLOR;
    polyline.strokeWidth = 5.f;
    polyline.map = self.mapView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

-(UIBezierPath *)quadCurvedPathWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    if (points.count == 2) {
        value = points[1];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
        return path;
    }
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = midPointForPoints(p1, p2);
        [path addQuadCurveToPoint:midPoint controlPoint:controlPointForPoints(midPoint, p1)];
        [path addQuadCurveToPoint:p2 controlPoint:controlPointForPoints(midPoint, p2)];
        
        p1 = p2;
    }
    return path;
}

static CGPoint midPointForPoints(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

static CGPoint controlPointForPoints(CGPoint p1, CGPoint p2) {
    CGPoint controlPoint = midPointForPoints(p1, p2);
    CGFloat diffY = fabs(p2.y - controlPoint.y);
    
    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;
    return controlPoint;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
