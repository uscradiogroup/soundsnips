//
//  SnipModel.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/20/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SnipModel : NSManagedObject

@property (nonatomic, retain) NSNumber * cuePoint;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSManagedObject *song;

@end
