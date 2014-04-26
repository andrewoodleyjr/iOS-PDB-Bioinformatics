//
//  atomObject.h
//  bio
//
//  Created by Harmon Group on 4/25/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface atomObject : NSObject


@property (nonatomic) int serial;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *altLoc;
@property (nonatomic, strong) NSString *resName;
@property (nonatomic, strong) NSString *chainID;
@property (nonatomic, strong) NSString *resSeq;
@property (nonatomic, strong) NSString *iCode;
@property (nonatomic, strong) NSString *x;
@property (nonatomic, strong) NSString *y;
@property (nonatomic, strong) NSString *z;
@property (nonatomic, strong) NSString *sequenceId;



@end
