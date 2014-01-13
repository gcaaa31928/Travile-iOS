/* Copyright (C) 2011 - 2013 Matej Kramny <matejkramny@gmail.com>
 * All rights reserved.
 */

#import "TMVillageOverviewViewController.h"
#import "AppDelegate.h"
#import "TMStorage.h"
#import "TMVillage.h"
#import "TMAccount.h"
#import "TMMovement.h"
#import "TMConstruction.h"
#import <QuartzCore/QuartzCore.h>
#import "TMAPNService.h"
#import "TMApplicationSettings.h"
#import "MBProgressHUD.h"

@interface TMVillageOverviewViewController () {
	TMStorage *storage;
	TMVillage *village;
	NSTimer *secondTimer;
	int constructionRows;
	int movementRows;
	MBProgressHUD *HUD;
	UITapGestureRecognizer *tapToCancel;
	
	NSArray *cells;
}

@end

@implementation TMVillageOverviewViewController

static NSString *viewTitle;

- (void)viewDidLoad
{
	viewTitle = NSLocalizedString(@"Overview", @"Overview view title");
	
	storage = [TMStorage sharedStorage];
	village = [[storage account] village];
	
	[self setRefreshControl:[[UIRefreshControl alloc] init]];
	[[self refreshControl] addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
	
	[[self tableView] setBackgroundView:nil];
	[self.navigationItem setTitle:viewTitle];
	//[self.navigationItem setHidesBackButton:NO];
	//[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Villages" style:UIBarButtonItemStyleBordered target:self action:@selector(back:)]];
	
	[self buildCells];
	
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	@try {
		[storage.account removeObserver:self forKeyPath:@"village"];
	}
	@catch (id exception) {
		// do nothing.. means it isn't registered as observer
	}
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	secondTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(secondTimerFired:) userInfo:nil repeats:YES];
	[[self tableView] reloadData];
	
	[[storage account] addObserver:self forKeyPath:@"village" options:NSKeyValueObservingOptionNew context:nil];
	
	[self.navigationItem setTitle:viewTitle];
	
	if (village != storage.account.village) {
		// Village changed..
		village = storage.account.village;
		
		if (!village.hasDownloaded) {
			// Download the village.
			HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			[HUD setLabelText:[NSString stringWithFormat:NSLocalizedString(@"Loading %@", @"Shown in HUD when loading a village"), village.name]];
			[HUD setDetailsLabelText:NSLocalizedString(@"Tap to cancel", @"Shown in HUD, informative to cancel the operation")];
			tapToCancel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToCancel:)];
			[HUD addGestureRecognizer:tapToCancel];
			[village addObserver:self forKeyPath:@"hasDownloaded" options:NSKeyValueObservingOptionNew context:nil];
			[village downloadAndParse];
		}
		
		[self buildCells];
		[self.tableView reloadData];
	}
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (secondTimer)
		[secondTimer invalidate];
	
	@try {
		[storage.account removeObserver:self forKeyPath:@"village"];
		[storage.account removeObserver:self forKeyPath:@"status"];
		[self.refreshControl endRefreshing];
	}
	@catch (id exception) {
		// do nothing.. means it isn't registered as observer
	}
	
	[super viewWillDisappear:animated];
}

- (void)didBeginRefreshing:(id)sender {
	[[storage account] addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
	
	[[storage account] refreshAccountWithMap:ARVillage];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"status"]) {
		if (([[change objectForKey:NSKeyValueChangeNewKey] intValue] & ARefreshed) != 0) {
			// Refreshed
			[[storage account] removeObserver:self forKeyPath:@"status"];
			[self.refreshControl endRefreshing];
			// Reload data
			[self buildCells];
			[[self tableView] reloadData];
		}
	} else if ([keyPath isEqualToString:@"hasDownloaded"]) {
		[self finishedLoadingVillageWithHUD];
	} else if ([keyPath isEqualToString:@"village"]) {
		if (village != storage.account.village && storage.account.village != nil) {
			// Village changed..
			village = storage.account.village;
			
			if (!village.hasDownloaded) {
				// Download the village.
				HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
				[HUD setLabelText:[NSString stringWithFormat:NSLocalizedString(@"Loading %@", @"Shown in HUD when loading a village"), village.name]];
				[HUD setDetailsLabelText:NSLocalizedString(@"Tap to cancel", @"Shown in HUD, informative to cancel the operation")];
				tapToCancel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToCancel:)];
				[HUD addGestureRecognizer:tapToCancel];
				[village addObserver:self forKeyPath:@"hasDownloaded" options:NSKeyValueObservingOptionNew context:nil];
				[village downloadAndParse];
			}
			
			[self buildCells];
			[self.tableView reloadData];
		}
	}
}

- (void)finishedLoadingVillageWithHUD {
	@try {
		[village removeObserver:self forKeyPath:@"hasDownloaded"];
		[HUD removeGestureRecognizer:tapToCancel];
		tapToCancel = nil;
		[HUD hide:YES];
	}
	@catch (NSException *exception) {
	}
	@finally {
		[self buildCells];
		[self.tableView reloadData];
	}
}

- (void)tappedToCancel:(id)sender {
	[self finishedLoadingVillageWithHUD];
}

#pragma mark - Table view data source

- (void)buildCells {
	NSMutableArray *sections = [[NSMutableArray alloc] init];
	
	[sections addObject:@{@"header": village.name,
	 @"cells": @[
	 @{ @"name": NSLocalizedString(@"Population", nil), @"value": [NSString stringWithFormat:@"%d", village.population]},
	 @{ @"name": NSLocalizedString(@"Loyalty", nil), @"value": [NSString stringWithFormat:@"%d", village.loyalty]}
	 ]
	 }];
	
	NSMutableArray *incoming = [[NSMutableArray alloc] init];
	NSMutableArray *outgoing = [[NSMutableArray alloc] init];
	NSMutableArray *other = [[NSMutableArray alloc] init];
	for (TMMovement *movement in village.movements) {
		NSDictionary *cell = @{@"name": movement.name,
						 @"value": movement.finished,};
		if ((movement.type & TMMovementTypeIncoming) != 0) {
			// Incoming section
			[incoming addObject:cell];
		} else if ((movement.type & TMMovementTypeOutgoing) != 0) {
			[outgoing addObject:cell];
		} else {
			[other addObject:cell];
		}
	}
	
	if (incoming.count > 0) [sections addObject:@{@"header": NSLocalizedString(@"Incoming", @"Movements related"),
							 @"cells": incoming}];
	if (outgoing.count > 0) [sections addObject:@{@"header": NSLocalizedString(@"Outgoing", @"Movements related"),
							 @"cells": outgoing}];
	if (other.count > 0) [sections addObject:@{@"header": NSLocalizedString(@"Other Movements", @"Movements related"),
						  @"cells": other}];
	
	NSMutableArray *constructions = [[NSMutableArray alloc] init];
	for (TMConstruction *construction in village.constructions) {
		[constructions addObject:@{@"name": construction.name, @"value": ([construction finishTime] == nil ? [NSNull null] : [construction finishTime]) }];
	}
	if (constructions.count > 0) {
		[sections addObject:@{@"header": NSLocalizedString(@"Constructions", @""),
		 @"cells": constructions,
		 @"footer": NSLocalizedString(@"Tap on a construction or movement to schedule a notification", @"Informing the user to tap on a movement to schedula a push notification")}];
	}
	
	[sections addObject:@{@"header": @"",
						  @"cells": @[
									@{@"name": @"Farm List", @"value": @"", @"segue": @"farm list"},
									@{@"name": @"Resources", @"value": @"", @"segue": @"resources"},
									@{@"name": @"Buildings", @"value": @"", @"segue": @"buildings"},
									@{@"name": @"Troops", @"value": @"", @"segue": @"troops"}
									  ],
						  @"footer": @""}
	 ];
	
	cells = sections;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [cells count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[cells objectAtIndex:section] objectForKey:@"cells"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *(^calculateRemainingTimeFromDate)(NSDate *) = ^(NSDate *date) {
		if (date == nil)
			return [NSString stringWithString:NSLocalizedString(@"Event Pending", @"Pending event message")];
		
		int diff = [date timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970];
		
		if (diff <= 0) {
			// Event happened..
			return [NSString stringWithString:NSLocalizedString(@"Event Happened", @"Timer has reached < 0 seconds")];
		}
		
		int hours = diff / (60 * 60);
		NSString *hoursString = hours < 10 ? [NSString stringWithFormat:@"0%d", hours] : [NSString stringWithFormat:@"%d", hours];
		diff -= hours * (60 * 60);
		int minutes = diff / 60;
		NSString *minutesString = minutes < 10 ? [NSString stringWithFormat:@"0%d", minutes] : [NSString stringWithFormat:@"%d", minutes];
		diff -= minutes * 60;
		int seconds = diff;
		NSString *secondsString = seconds < 10 ? [NSString stringWithFormat:@"0%d", seconds] : [NSString stringWithFormat:@"%d", seconds];
		
		if (hours > 0)
			return [NSString stringWithFormat:@"%@:%@:%@ %@", hoursString, minutesString, secondsString, NSLocalizedString(@"hrs", @"Timers suffix (hours remaining)")];
		else if (minutes > 0)
			return [NSString stringWithFormat:@"%@:%@ %@", minutesString, secondsString, NSLocalizedString(@"min", @"Timers suffix (minutes remaining)")];
		else
			return [NSString stringWithFormat:@"%@ %@", secondsString, NSLocalizedString(@"sec", @"Timers suffix (seconds remaining)")];
	};
	
	static NSString *rightDetailCellIdentifier = @"RightDetail";
	static NSString *rightDetailSelectableCellIdentifier = @"RightDetailSelectable";
	__unused static NSString *basicCellIdentifier = @"Basic";
	__unused static NSString *basicSelectableCellIdentifier = @"BasicSelectable";
	
	NSDictionary *cellDicitionary = [[[cells objectAtIndex:indexPath.section] objectForKey:@"cells"] objectAtIndex:indexPath.row];
	
	UITableViewCell *cell;
	id value = [cellDicitionary objectForKey:@"value"];
	if ([value isKindOfClass:[NSDate class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:rightDetailSelectableCellIdentifier];
		cell.detailTextLabel.text = calculateRemainingTimeFromDate((NSDate *)value);
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:rightDetailCellIdentifier];
		if ([value isKindOfClass:[NSString class]]) {
			cell.detailTextLabel.text = (NSString *)value;
		} else {
			cell.detailTextLabel.text = @"--:--:--";
		}
		
		if (cell.detailTextLabel.text.length == 0) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	cell.textLabel.text = [cellDicitionary objectForKey:@"name"];
	
	return cell;
}

- (IBAction)secondTimerFired:(id)sender {
	[self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[cells objectAtIndex:section] objectForKey:@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return [[cells objectAtIndex:section] objectForKey:@"footer"];
}

#pragma mark - Table view delegate

static NSDate *notificationDate;
static NSString *notificationTitle;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *cell = [[[cells objectAtIndex:indexPath.section] objectForKey:@"cells"] objectAtIndex:indexPath.row];
	
	NSString *segue = [cell objectForKey:@"segue"];
	if (segue != nil) {
		[self performSegueWithIdentifier:segue sender:nil];
		return;
	}
	
	id value = [cell objectForKey:@"value"];
	if ([value isKindOfClass:[NSDate class]]) {
		notificationTitle = [cell objectForKey:@"name"];
		notificationDate = (NSDate *)value;
		if (DEBUG_APP)
			notificationDate = [NSDate dateWithTimeIntervalSinceNow:40];
	} else {
		return;
	}
	
	if (storage.appSettings.pushNotifications) {
		[[TMAPNService sharedInstance] scheduleNotification:notificationDate withMessageTitle:notificationTitle];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enable Push Notifications?", nil) message:NSLocalizedString(@"Push notifications are not enabled right now.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Not now", nil) otherButtonTitles:NSLocalizedString(@"Enable", nil), nil];
		[alert show];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		// Enable
		storage.appSettings.pushNotifications = true;
		[[TMAPNService sharedInstance] scheduleNotification:notificationDate withMessageTitle:notificationTitle];
		[storage saveData];
	}
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
