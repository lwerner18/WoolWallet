//
//  OpenCVWrapper.h
//  WoolWallet
//
//  Created by Mac on 3/23/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (UIImage *)getImageColor:(UIImage *)inputImage;
+ (UIImage *)detectEdges:(UIImage*) inputImage;
+ (UIImage *)getEdgesImage:(UIImage*) inputImage;
+ (UIImage *)getContourImage:(UIImage*) inputImage;
+ (UIImage *)findAndDrawContours:(UIImage *) edges;
+ (UIImage *)getImageColorfromMask:(UIImage*) inputImage : (UIImage*) mask;
+ (UIImage *)morphologicalClose:(UIImage *)inputImage;
@end

NS_ASSUME_NONNULL_END
