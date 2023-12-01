//
//  Orientation.m
//

#import "Orientation.h"
#import "RCTEventDispatcher.h"

@implementation Orientation
@synthesize bridge = _bridge;

static UIInterfaceOrientationMask _orientation = UIInterfaceOrientationMaskAllButUpsideDown;
static BOOL isLock = NO;
static NSString *currentOrientationStr = @"UNKNOWN";
+ (void)setOrientation: (UIInterfaceOrientationMask)orientation {
    _orientation = orientation;
    isLock = orientation != UIInterfaceOrientationMaskAll;
}
+ (UIInterfaceOrientationMask)getOrientation {
  return _orientation;
}

- (instancetype)init
{
  if ((self = [super init])) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  }
  return self;

}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (isLock) {
        return;
    }
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    orientation = [self correctOrientationIfNeeded:orientation];
    NSString *orientationStr = [self getSpecificOrientationStr:orientation];
    currentOrientationStr = orientationStr;
   
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"specificOrientationDidChange"
                                                body:@{@"specificOrientation": orientationStr}];

    [self.bridge.eventDispatcher sendDeviceEventWithName:@"orientationDidChange"
                                                body:@{@"orientation": [self getOrientationStr:orientation]}];

}

- (void)sendEvent: (NSString *) eventName {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    orientation = [self correctOrientationIfNeeded:orientation];
    NSString* name = [self getSpecificOrientationStr:orientation];
    if (name == eventName) {
        return;
    }
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"specificOrientationDidChange"
                                                body:@{@"specificOrientation": eventName}];
}

- (UIDeviceOrientation)correctOrientationIfNeeded:(UIDeviceOrientation)orientation {
  if (orientation == UIDeviceOrientationUnknown ||
      orientation == UIDeviceOrientationFaceUp ||
      orientation == UIDeviceOrientationFaceDown) {
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (statusBarOrientation) {
      case UIInterfaceOrientationPortrait:
        orientation = UIDeviceOrientationPortrait;
        break;
      case UIInterfaceOrientationPortraitUpsideDown:
        orientation = UIDeviceOrientationPortraitUpsideDown;
        break;
      case UIInterfaceOrientationLandscapeLeft:
        orientation = UIDeviceOrientationLandscapeLeft;
        break;
      case UIInterfaceOrientationLandscapeRight:
        orientation = UIDeviceOrientationLandscapeRight;
        break;
      default:
        break;
    }
  }
  return orientation;
}

- (NSString *)getOrientationStr: (UIDeviceOrientation)orientation {
  NSString *orientationStr;
  switch (orientation) {
    case UIDeviceOrientationPortrait:
      orientationStr = @"PORTRAIT";
      break;
    case UIDeviceOrientationLandscapeLeft:
    case UIDeviceOrientationLandscapeRight:

      orientationStr = @"LANDSCAPE";
      break;

    case UIDeviceOrientationPortraitUpsideDown:
      orientationStr = @"PORTRAITUPSIDEDOWN";
      break;

    default:
      orientationStr = @"UNKNOWN";
      break;
  }
  return orientationStr;
}

- (NSString *)getSpecificOrientationStr: (UIDeviceOrientation)orientation {
  NSString *orientationStr;
  switch (orientation) {
    case UIDeviceOrientationPortrait:
      orientationStr = @"PORTRAIT";
      break;

    case UIDeviceOrientationLandscapeLeft:
      orientationStr = @"LANDSCAPE-LEFT";
      break;

    case UIDeviceOrientationLandscapeRight:
      orientationStr = @"LANDSCAPE-RIGHT";
      break;

    case UIDeviceOrientationPortraitUpsideDown:
      orientationStr = currentOrientationStr;
      break;

    default:
      orientationStr = @"UNKNOWN";
      break;
  }
  return orientationStr;
}

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup
{
   return NO;
}

RCT_EXPORT_METHOD(getOrientation:(RCTResponseSenderBlock)callback)
{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  orientation = [self correctOrientationIfNeeded:orientation];
  NSString *orientationStr = [self getOrientationStr:orientation];
  callback(@[[NSNull null], orientationStr]);
}

RCT_EXPORT_METHOD(getSpecificOrientation:(RCTResponseSenderBlock)callback)
{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  orientation = [self correctOrientationIfNeeded:orientation];
  NSString *orientationStr = [self getSpecificOrientationStr:orientation];
  callback(@[[NSNull null], orientationStr]);
}

RCT_EXPORT_METHOD(lockToPortrait)
{
  #if DEBUG
    NSLog(@"Locked to Portrait");
  #endif
  [Orientation setOrientation:UIInterfaceOrientationMaskPortrait];
    
  [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
    [self sendEvent:@"PORTRAIT"];
  }];

}

RCT_EXPORT_METHOD(lockToLandscape)
{
  #if DEBUG
    NSLog(@"Locked to Landscape");
  #endif
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  NSString *orientationStr = [self getSpecificOrientationStr:orientation];
  if ([orientationStr isEqualToString:@"LANDSCAPE-LEFT"]) {
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
      
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
      [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
      [UIViewController attemptRotationToDeviceOrientation];
      [self sendEvent:@"LANDSCAPE-LEFT"];
    }];
  } else {
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
      
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
      [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
      [UIViewController attemptRotationToDeviceOrientation];
      [self sendEvent:@"LANDSCAPE-RIGHT"];
    }];
  }
}

RCT_EXPORT_METHOD(lockToLandscapeRight)
{
  #if DEBUG
    NSLog(@"Locked to Landscape Right");
  #endif
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeLeft];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        [self sendEvent:@"LANDSCAPE-RIGHT"];
    }];

}

RCT_EXPORT_METHOD(lockToLandscapeLeft)
{
  #if DEBUG
    NSLog(@"Locked to Landscape Left");
  #endif
  [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeRight];
   
  [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    // this seems counter intuitive
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
    [self sendEvent:@"LANDSCAPE-LEFT"];
  }];

}

RCT_EXPORT_METHOD(unlockAllOrientations)
{
  #if DEBUG
    NSLog(@"Unlock All Orientations");
  #endif
  [Orientation setOrientation:UIInterfaceOrientationMaskAll];
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  orientation = [self correctOrientationIfNeeded:orientation];
   
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"specificOrientationDidChange"
                                                body:@{@"specificOrientation": [self getSpecificOrientationStr:orientation]}];
  [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
      // this seems counter intuitive
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationUnknown] forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
  }];
//  AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//  delegate.orientation = 3;
}

- (NSDictionary *)constantsToExport
{

  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  NSString *orientationStr = [self getOrientationStr:orientation];

  return @{
    @"initialOrientation": orientationStr
  };
}

@end
