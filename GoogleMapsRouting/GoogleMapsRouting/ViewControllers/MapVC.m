//
//  MapVC.m
//  GoogleMapsRouting
//
//  Created by YAUHENI DROBAU on 11/01/2017.
//  Copyright © 2017 YAUHENI DROBAU. All rights reserved.
//

#import "MapVC.h"
#import <CoreLocation/CoreLocation.h>
#import "SAMCubicSpline.h"

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
    
    self.points = @[[NSValue valueWithCGPoint:CGPointMake(53.8, 27)],
                    [NSValue valueWithCGPoint:CGPointMake(53, 29)],
                    [NSValue valueWithCGPoint:CGPointMake(52.715543, 28.814323)],
                    [NSValue valueWithCGPoint:CGPointMake(52.278639, 28.646759)],
                    [NSValue valueWithCGPoint:CGPointMake(52.726706, 28.679718)],
                    [NSValue valueWithCGPoint:CGPointMake(52.573407, 27.657989)],
                    [NSValue valueWithCGPoint:CGPointMake(52.846305, 26.592316)],
                    [NSValue valueWithCGPoint:CGPointMake(52.560051, 25.636505)],
                    [NSValue valueWithCGPoint:CGPointMake(53.628739, 26.526398)],
                    [NSValue valueWithCGPoint:CGPointMake(53.687333, 27.042755)]];
        //DEMO
//    CGSize graphSize = CGSizeMake(100.0f, 100.0f);
//    for (CGFloat x = 0.0f; x < size.width; x++) {
//        // Get the Y value of our point
//        CGFloat y = [spline interpolate:x / size.width] * size.height;
//        
//        // Add the point to the context's path
//        if (x == 0.0f) {
//            CGContextMoveToPoint(context, x, y);
//        } else {
//            CGContextAddLineToPoint(context, x, y);
//        }
//    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    SAMCubicSpline *spline = [[SAMCubicSpline alloc] initWithPoints:_points];
    CGSize graphSize = self.mapView.frame.size;
    for (CGFloat x = 0.0f; x < 1.4; x = x + 0.014) {
        // Get the Y value of our point
        CGFloat y = [spline interpolate:x / 1.4] * 1;
        
        [_coordinatesArray addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        // Add the point to the context's path
        if (x == 0.0f) {
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
    }
    
    self.coordinatesArray = [[NSMutableArray alloc]init];
//    [self drawBezier:self.view.bounds inContext:context];
    
    
    CGPoint firstPoint = ((NSValue *)_points.firstObject).CGPointValue;
    CGPoint lastPoint = ((NSValue *)_points.lastObject).CGPointValue;
    CLLocationDegrees startLatitudeDeg = firstPoint.x;
    CLLocationDegrees startLongitudeDeg = firstPoint.y;
    CLLocationDegrees endLatitudeDeg = lastPoint.x;
    CLLocationDegrees endLongitudeDeg = lastPoint.y;
    
    CLLocationCoordinate2D startPosition = CLLocationCoordinate2DMake(startLatitudeDeg, startLongitudeDeg);
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:startLatitudeDeg
                                longitude:startLongitudeDeg
                                     zoom:2
                                  bearing:30
                             viewingAngle:40];
    self.mapView.camera = camera;
    GMSMutablePath *path = [GMSMutablePath path];
    
    CGPathRef yourCGPath = [self quadCurvedPathWithPoints:self.points].CGPath;
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void * _Nullable)(bezierPoints), MyCGPathApplierFunc);
    

    
    for (NSValue *point in _coordinatesArray) {
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
    polyline.strokeWidth = 2.f;
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

- (UIBezierPath *)quadCurvedPathWithPoints:(NSArray *)points
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
    [path stroke];
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

- (void)drawBezier:(CGRect)rect inContext:(CGContextRef)context {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGPoint startPt = [[_points objectAtIndex:0] CGPointValue];
    CGPoint endPt = [[_points objectAtIndex:(self.points.count - 1)] CGPointValue];
    
    float amount = endPt.x - startPt.x;
    
    int (^factorial)(int k) = ^(int k) {
        if (k == 0)
        {
            return 1;
        }
        int m = 1;
        for (int i = 1; i <= k; i++)
        {
            m *= i;
        }
        return m;
    };
    
    
    //< Curve Equation
    float (^bezierSpline)(int rank, float ux) = ^(int rank, float ux) {
        
        float p = 0.0f;
        
        for (int i = 0; i < rank; i++)
        {
            CGPoint pt = [[_points objectAtIndex:i] CGPointValue];
            
            p += pt.y * powf((1 - ux), (rank - i - 1)) * powf(ux, i) * (factorial(rank - 1) / (factorial(i) * factorial(rank - i - 1)));
        }
        
        return p;
    };
    
    //    for (int i = 0; i < MIN(self.pointCount, [_points count]); i++)
    //    {
    //
    //        CGPoint pt = [[_points objectAtIndex:i] CGPointValue];
    //
    //        float u = (pt.x - startPt.x) / amount;
    //
    //        if (i == 0)
    //        {
    //            [path moveToPoint:pt];
    //        }
    //        else
    //        {
    //            [path addLineToPoint:CGPointMake(pt.x, bezierSpline(self.pointCount, u))];
    //            if (i < ([_points count] - 1))
    //            {
    //                CGPoint prevPt = [[_points objectAtIndex:(i-1)] CGPointValue];
    //                CGPoint nextPt = [[_points objectAtIndex:(i+1)] CGPointValue];
    //                [path addCurveToPoint:pt controlPoint1:prevPt controlPoint2:nextPt];
    //            }
    //            else
    //            {
    //                [path addLineToPoint:pt];
    //            }
    //        }
    //    }
    
    [path moveToPoint:startPt];
    
    for (float curX = startPt.x; (curX - endPt.x) < 1e-5; curX += 1.0f)
    {
        float u = (curX - startPt.x) / amount;
        [path addLineToPoint:CGPointMake(curX, bezierSpline(self.points.count, u))];
        CGPoint point = CGPointMake(curX, bezierSpline(self.points.count, u));
        [_coordinatesArray addObject:[NSValue valueWithCGPoint:point]];
    }
    
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
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
