//
//  SQLiteDatabase.m
//  bio
//
//  Created by Harmon Group on 4/15/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import "SQLiteDatabase.h"

@implementation SQLiteDatabase

static SQLiteDatabase *_database;

+ (SQLiteDatabase *)database {
    if (_database == nil) {
        _database = [[SQLiteDatabase alloc] init];
    }
    return _database;
}

- (id)init {
    if ((self = [super init])) {
        NSString *sqLiteDb = [[NSBundle mainBundle] pathForResource:@"dna"
                                                             ofType:@"sqlite3"];
        
        if (sqlite3_open([sqLiteDb UTF8String], &_database) != SQLITE_OK) {
            NSLog(@"Failted to open database!");
        }
        else{
            NSLog(@"Opened db");
        }
    }
    return self;
}

-(NSMutableArray *)getDNAFromDatabase:(NSString *)query
{
    NSMutableArray *dnaList = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
        == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            //int uniqueId = sqlite3_column_int(statement, 0);
            char *dnaName = (char *) sqlite3_column_text(statement, 0);
            NSString *name = [[NSString alloc] initWithUTF8String:dnaName];
            [dnaList addObject:name];
            
        }
        sqlite3_finalize(statement);
    }
    return dnaList;
}

@end
