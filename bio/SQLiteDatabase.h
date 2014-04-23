//
//  SQLiteDatabase.h
//  bio
//
//  Created by Harmon Group on 4/15/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLiteDatabase : NSObject{
    sqlite3 *_database;
}

+ (SQLiteDatabase *) database;

-(NSMutableArray *)getDNAFromDatabase:(NSString *)query;
-(BOOL)noReturnDNADatabaseQuery:(NSString *)query;

@end

