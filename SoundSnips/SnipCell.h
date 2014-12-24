//
//  SnipCell.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/12/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SnipLabel.h"

@interface SnipCell : UITableViewCell

+(NSString*)reuseIdentifier;
+(CGFloat)heightForText:(NSString*)text;

@property (assign) BOOL			shouldDrawBottomSeparator;
@property (strong) SnipLabel*	snipLabel;

@end
