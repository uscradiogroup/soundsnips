//
//  SoftPopup.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 5/10/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SoftPopup : UIView

+(SoftPopup*)sharedSoftPopup;
-(void)show:(UIImage*)image text:(NSString*)text;

@end
