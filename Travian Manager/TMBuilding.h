// This code is distributed under the terms and conditions of the MIT license.

/* * Copyright (C) 2011 - 2013 Matej Kramny <matejkramny@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "TMPages.h"
#import "TravianPageParsingProtocol.h"

@class TMBuildingAction;
@class TMVillage;
@class TMResources;
@class TMAccount;
@class Coordinate;
@class HTMLNode;

@interface TMBuilding : NSObject <NSCoding, NSURLConnectionDataDelegate, NSURLConnectionDelegate, TMPageParsingProtocol>

@property (nonatomic, strong) NSString *bid; // Building access ID
@property (assign) TravianBuildings gid; // Building GID
@property (nonatomic, strong) NSString *name; // Building Name (localised in browser)
@property (nonatomic, strong) NSString *description; // What building does (^)
@property (nonatomic, strong) NSDictionary *properties; // Building properties.
@property (assign) TravianPages page; // TPVillage | TPResource
@property (nonatomic, strong) TMResources *resources; // Required resources to build/upgrade this building
@property (assign) int level; // Building level
@property (nonatomic, strong) NSArray *availableBuildings; // When user wants to build something on empty spot (gid0) then this array is used as a list of what user can build on that location. List contains objects typeof Building
@property (assign) bool finishedLoading;
@property (nonatomic, strong) NSString *upgradeURLString; // Serves as container for contract link
@property (nonatomic, strong) NSString *cannotBuildReason; // Reason we cannot build
@property (nonatomic, strong) NSArray *buildConditionsDone; // List of build conditions
@property (nonatomic, strong) NSArray *buildConditionsError; // Errorneous build conditons (unfulfilled)
@property (assign) CGPoint coordinates; // Where the building is on a visual map
@property (assign) bool isBeingUpgraded; // Indicates whether this building is being currently upgraded.
@property (nonatomic, strong) NSArray *actions; // Building Actions - such as Research a troop
@property (nonatomic, strong) HTMLNode *buildDiv; // Contract HTMLNode

// Building in what village?
@property (nonatomic, weak) TMVillage *parent;

@property (nonatomic, strong) NSString *finishedLoadingKVOIdentifier; // Holds value that tells other objects what key to observe if they want to check whether the object has finished loading

- (void)buildFromAccount:(TMAccount *)account;
- (void)fetchDescription;
- (void)fetchDescriptionFromNode:(HTMLNode *)node;
- (void)buildFromURL:(NSURL *)url;
- (void)fetchContractConditionsFromContractID:(HTMLNode *)contract;
- (void)fetchResourcesFromContract:(HTMLNode *)contract;
- (void)fetchActionsFromIDBuild:(HTMLNode *)buildID;

@end
