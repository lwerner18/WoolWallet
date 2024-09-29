//
//  OpenCVWrapper.m
//  WoolWallet
//
//  Created by Mac on 3/23/24.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <iostream>

/*
 * add a method convertToMat to UIImage class
 */
@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists {
    if (self.imageOrientation == UIImageOrientationRight) {
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat, alphaExists);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}
@end

@implementation OpenCVWrapper
+ (UIImage *)detectEdges:(UIImage*) inputImage {
    // Step 1: Convert UIImage to cv::Mat
    cv::Mat image;
    UIImageToMat(inputImage, image);
    
    //Convert to grayscale
    cv::Mat gray;
    cvtColor(image, gray, cv::COLOR_BGR2GRAY);
    
    // Apply Gaussian Blur
    cv::Mat blurredImage;
    cv::GaussianBlur(gray, blurredImage, cv::Size(3, 3), 1.5);
    
    // Enhance contrast using CLAHE
    cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(2.0, cv::Size(8, 8));
    cv::Mat contrastMat;
    clahe->apply(blurredImage, contrastMat);
    
    cv::Mat bin;
    double otsu_thresh_val = cv::threshold(contrastMat, bin, 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    
    cv::Mat thresh;
    cv::adaptiveThreshold(contrastMat, thresh, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 11, 2);
    
    double lower_thresh = 0.5 * otsu_thresh_val;
    double upper_thresh = 1.25 * otsu_thresh_val;
    
    double avgBrightness = cv::mean(thresh)[0];
    
    if (avgBrightness > 128) {  // Assuming the scale is 0-255
        // Yarn is likely darker than the background
        cv::bitwise_not(thresh, thresh);
    }
    
//    // Edge detection using Canny
//    cv::Mat edges;
//    Canny(thresh, edges, lower_thresh, upper_thresh);
//    
//    // Morphological closing to connect edges
//    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5));
//    cv::Mat closedEdges;
//    morphologyEx(thresh, closedEdges, cv::MORPH_CLOSE, kernel);

    
    return MatToUIImage(thresh);
    
  
}

+ (UIImage *)getEdgesImage:(UIImage*) inputImage {
    return [self detectEdges:inputImage];
}

+ (UIImage *)findAndDrawContours:(UIImage *) edges {
    cv::Mat matEdges;
    UIImageToMat(edges, matEdges);
    
    std::vector<std::vector<cv::Point>> contours;
    findContours(matEdges, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    // Step 3: Choose the largest contour to segment the object
    std::vector<std::vector<cv::Point>> filteredContours;
    double minArea = 150.0; // Adjust this threshold based on your specific needs
    for (size_t i = 0; i < contours.size(); i++) {
        if (cv::contourArea(contours[i]) > minArea) {
            filteredContours.push_back(contours[i]);
        }
    }
    
    // Create a mask for the largest contour
    cv::Mat contourMask = cv::Mat::zeros(matEdges.size(), CV_8UC1);
    drawContours(contourMask, std::vector<std::vector<cv::Point>>{filteredContours}, -1, cv::Scalar(255), cv::FILLED);
    
    UIImage* firstCountor = MatToUIImage(contourMask);
    
    std::vector<std::vector<cv::Point>> secondContours;
    findContours(contourMask, secondContours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    double maxArea = 0;
    std::vector<cv::Point> largestContour;
    for (const auto& contour : secondContours) {
        double area = cv::contourArea(contour);
        if (area > maxArea) {
            maxArea = area;
            largestContour = contour;
        }
    }
    
    cv::Mat secondContourMask = cv::Mat::zeros(contourMask.size(), CV_8UC1);
    drawContours(secondContourMask, std::vector<std::vector<cv::Point>>{largestContour}, -1, cv::Scalar(255), cv::FILLED);
    
    
    return MatToUIImage(secondContourMask);
}

+ (UIImage *)getContourImage:(UIImage*) inputImage {
    return [self findAndDrawContours:[self detectEdges:inputImage]];
}

+ (UIImage *)getImageColor:(UIImage*) inputImage {
    // Step 1: Convert UIImage to cv::Mat
    cv::Mat matImage;
    UIImageToMat(inputImage, matImage);
    
    UIImage* edges = [self detectEdges:inputImage];
    
    cv::Mat contourMask;
    UIImageToMat([self findAndDrawContours:edges], contourMask);
    
    cv::Mat yarnOnly;
    matImage.copyTo(yarnOnly, contourMask);  // Use dilated edges as a mask to isolate yarn from the background
    
    return MatToUIImage(yarnOnly);
    
    
//    // Step 4: Analyze color within the mask
//    cv::Scalar objectColor = cv::mean(matImage, contourMask);
//    
//    // Convert the color to a 1x1 image for visualization
//    cv::Mat colorSwatch(1, 1, CV_8UC3, objectColor);
//    UIImage* colorSwatchImage = MatToUIImage(colorSwatch);
//    
//    return colorSwatchImage;
}

+ (UIImage *)getImageColorFromMask:(UIImage*)inputImage : (UIImage*)mask {
    // Step 1: Convert UIImage to cv::Mat
    cv::Mat matImage;
    UIImageToMat(inputImage, matImage);
    
    cv::Mat contourMask;
    UIImageToMat([self findAndDrawContours:mask], contourMask);
    
    // Resize the image
    cv::Mat resizedMat;
    cv::resize(matImage, resizedMat, cv::Size(256, 256));
    
    cv::Mat yarnOnly;
    resizedMat.copyTo(yarnOnly, contourMask);  // Use dilated edges as a mask to isolate yarn from the background
    
    return MatToUIImage(yarnOnly);
}

+ (UIImage *)morphologicalClose:(UIImage *)inputImage {
    // Step 1: Convert UIImage to cv::Mat
    cv::Mat matImage;
    UIImageToMat(inputImage, matImage);
    
    // Convert to grayscale if not already
    if (matImage.channels() > 1) {
        cv::cvtColor(matImage, matImage, cv::COLOR_BGR2GRAY);
    }
    
    // Apply threshold if the image is not binary
    cv::threshold(matImage, matImage, 127, 255, cv::THRESH_BINARY);
    
    // Define the structuring element/kernel size
    int kernelSize = 15;  // You can adjust this size based on your specific needs
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(kernelSize, kernelSize));
    
    // Perform morphological closing
    cv::morphologyEx(matImage, matImage, cv::MORPH_CLOSE, kernel);
    
    return MatToUIImage(matImage);
}

@end
