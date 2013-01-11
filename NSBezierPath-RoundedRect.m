#import "NSBezierPath-RoundedRect.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSBezierPath (RoundedRect)

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius
{
  NSBezierPath *result = [NSBezierPath bezierPath];
  [result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
  return result;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius
{
  if (!NSIsEmptyRect(rect))
  {
    if (radius > 0.0)
    {
      float clampedRadius = MIN(radius, 0.5 * MIN(rect.size.width, rect.size.height));
      
      NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
      NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
      NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
      
      [self moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
      [self appendBezierPathWithArcFromPoint:topLeft     toPoint:rect.origin radius:clampedRadius];
      [self appendBezierPathWithArcFromPoint:rect.origin toPoint:bottomRight radius:clampedRadius];
      [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight    radius:clampedRadius];
      [self appendBezierPathWithArcFromPoint:topRight    toPoint:topLeft     radius:clampedRadius];
      [self closePath];
    }
    else
    {
      [self appendBezierPathWithRect:rect];
    }
  }
}

@end