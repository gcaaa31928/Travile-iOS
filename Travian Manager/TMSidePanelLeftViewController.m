/* Copyright (C) 2011 - 2013 Matej Kramny <matejkramny@gmail.com>
 * All rights reserved.
 */

#import "TMSidePanelLeftViewController.h"
#import "JASidePanelController.h"
#import "TMSidePanelViewController.h"
#import "TMStorage.h"
#import "TMAccount.h"
#import "TMVillage.h"
#import "AppDelegate.h"
#import "TMMovement.h"
#import "TMConstruction.h"
#import "TMDarkImageCell.h"
#import <QuartzCore/QuartzCore.h>

@interface TMSidePanelLeftViewController () {
	__weak TMStorage *storage;
	UIViewController *currentViewController;
	NSIndexPath *currentViewControllerIndexPath;
	bool showsVillage;
	NSIndexPath *currentVillageIndexPath; // indexpath of active village
	NSIndexPath *lastVillageIndexPath;
}

@end

@implementation TMSidePanelLeftViewController

static bool firstTime = true;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	showsVillage = false;
}

- (void)viewWillAppear:(BOOL)animated {
	storage = [TMStorage sharedStorage];
	
	if (firstTime) {
		firstTime = false;
		currentViewControllerIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
		currentViewController = [[TMSidePanelViewController sharedInstance] getMessages];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (showsVillage)
		return storage.account.village.movements.count == 0 && storage.account.village.constructions.count == 0 ? 2 : 3;
	else
		return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (showsVillage) {
		if (section == 0)
			return 1;
		else if (section == 1)
			return 5;
		else if (section == 2) {
			TMVillage *village = [storage account].village;
			int count = 0;
			if (village.movements && [village.movements count] > 0)
				count += [village.movements count];
			if (village.constructions)
				count += [village.constructions count];
			
			return count;
		}
	} else {
		if (section == 0) {
			return 1;
		} else if (section == 1) {
			return 4;
		} else {
			return storage.account.villages.count;
		}
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *BasicSelectableCellIdentifier = @"BasicSelectable";
	static UIImage *overviewImage;
	static UIImage *resourcesImage;
	static UIImage *troopsImage;
	static UIImage *buildingsImage;
	static UIImage *villagesImage;
	static UIImage *farmlistImage;
	static UIImage *accountImage;
	static UIImage *messagesImage;
	static UIImage *reportsImage;
	static UIImage *settingsImage;
	static UIImage *heroImage;
	
	if (!overviewImage) {
		overviewImage = [UIImage imageNamed:@"53-house-white.png"];
		resourcesImage = [UIImage imageNamed:@"48-fork-and-knife-white.png"];
		troopsImage = [UIImage imageNamed:@"115-bow-and-arrow-white.png"];
		buildingsImage = [UIImage imageNamed:@"177-building-white.png"];
		villagesImage = [UIImage imageNamed:@"60-signpost-white.png"];
		farmlistImage = [UIImage imageNamed:@"134-viking-white.png"];
		accountImage = [UIImage imageNamed:@"21-skull-white.png"];
		heroImage = [UIImage imageNamed:@"108-badge-white.png"];
		messagesImage = [UIImage imageNamed:@"18-envelope-white.png"];
		reportsImage = [UIImage imageNamed:@"16-line-chart-white.png"];
		settingsImage = [UIImage imageNamed:@"20-gear2-white.png"];
	}
	
	TMDarkImageCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicSelectableCellIdentifier forIndexPath:indexPath];
	if (!cell)
		cell = [[TMDarkImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicSelectableCellIdentifier];
	NSString *text;
	
	if (showsVillage) {
		[cell setIndentTitle:NO];
		if (indexPath.section == 0) {
			text = NSLocalizedString(@"To Account", @"Sidebar cell text, returning from village list to account");
			cell.imageView.image = nil;
		} else if (indexPath.section == 1) {
			[cell setIndentTitle:YES];
			switch (indexPath.row) {
				case 0:
					text = NSLocalizedString(@"Overview", @"Overview view title");
					cell.imageView.image = overviewImage;
					break;
				case 1:
					text = NSLocalizedString(@"Resources", @"Sidebar cell text");
					cell.imageView.image = resourcesImage;
					break;
				case 2:
					text = NSLocalizedString(@"Troops", @"View title for Troops");
					cell.imageView.image = troopsImage;
					break;
				case 3:
					text = NSLocalizedString(@"Buildings", @"View title for Buildings");
					cell.imageView.image = buildingsImage;
					break;
				case 4:
					text = NSLocalizedString(@"Farm List", @"Sidebar cell text");
					cell.imageView.image = farmlistImage;
					break;
			}
		} else {
			// Movements & constructions section / events
			TMVillage *village = [storage account].village;
			if (village.movements && [village.movements count] > 0 && indexPath.row < [village.movements count]) {
				text = [(TMMovement *)[village.movements objectAtIndex:indexPath.row] name];
			} else {
				int row = indexPath.row;
				if (village.movements)
					row -= village.movements.count;
				
				text = [(TMConstruction *)[village.constructions objectAtIndex:row] name];
			}
		}
	} else {
		if (indexPath.section == 0) {
			[cell setIndentTitle:NO];
			text = NSLocalizedString(@"Logout", @"Sidebar cell text, logging out from account");
			cell.imageView.image = nil;
		} else if (indexPath.section == 1) {
			[cell setIndentTitle:YES];
			switch (indexPath.row) {
				case 0:
					text = NSLocalizedString(@"Messages", @"Messages view title");
					cell.imageView.image = messagesImage;
					break;
				case 1:
					text = NSLocalizedString(@"Reports", @"View title for Reports");
					cell.imageView.image = reportsImage;
					break;
				case 2:
					text = NSLocalizedString(@"Hero", @"Hero view title");
					cell.imageView.image = heroImage;
					break;
				case 3:
					text = NSLocalizedString(@"Settings", @"Title of the Settings view");
					cell.imageView.image = settingsImage;
					break;
			}
		} else {
			[cell setIndentTitle:NO];
			text = [[storage.account.villages objectAtIndex:indexPath.row] name];
			cell.imageView.image = nil;
		}
	}
	
	cell.textLabel.text = text;
	
	[AppDelegate setDarkCellAppearance:cell forIndexPath:indexPath];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *text;
	if (showsVillage) {
		if (section == 0) {
			return nil;
		} else if (section == 1) {
			text = [NSLocalizedString(@"Village ", @"Example: 'Village My Little Village'. Village name is appended to this string!") stringByAppendingString:storage.account.village.name];
		} else {
			text = NSLocalizedString(@"Village Events", @"Sidebar cell text");
		}
	} else if (section == 0) {
		return nil;
	} else if (section == 1) {
		text = NSLocalizedString(@"Account", @"Sidebar cell text");
	} else if (section == 2) {
		text = NSLocalizedString(@"Villages", @"Village view title");
	}
	
	return text;
}

- (void)back:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view delegate

- (void)transitionTableContent:(UITableView *)tableView {
	// Animates the tableview reload
	CATransition *transition = [CATransition animation];
	[transition setType:kCATransitionPush];
	[transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[transition setFillMode:kCAFillModeBoth];
	[transition setDuration:0.2];
	
	if (showsVillage) {
		[transition setSubtype:kCATransitionFromRight];
	} else {
		[transition setSubtype:kCATransitionFromLeft];
	}
	
	[tableView reloadData];
	
	if (!showsVillage && storage.account.village != nil) {
		// Not showing village and village is still active
	}
	
	[[tableView layer] addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TMSidePanelViewController *panel = [TMSidePanelViewController sharedInstance];
	UIViewController *newVC = nil;
	NSIndexPath *path = indexPath;
	
	if (showsVillage) {
		if (indexPath.section == 0) {
			showsVillage = false;
			[storage.account setVillage:nil];
			[self transitionTableContent:tableView];
			[tableView selectRowAtIndexPath:currentVillageIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
			return;
		} else if (indexPath.section == 1) {
			if (indexPath.row == 0)
				newVC = [panel getVillageOverview];
			else if (indexPath.row == 1)
				newVC = [panel getVillageResources];
			else if (indexPath.row == 2)
				newVC = [panel getVillageTroops];
			else if (indexPath.row == 3)
				newVC = [panel getVillageBuildings];
			else if (indexPath.row == 4)
				newVC = [panel getFarmList];
			lastVillageIndexPath = indexPath;
		} else {
			// Movements & constructions / events
			newVC = [panel getVillageOverview];
			path = [NSIndexPath indexPathForRow:0 inSection:0];
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			[tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	} else {
		if (indexPath.section == 0) {
			[storage.account deactivateAccount];
			
			firstTime = YES;
			
			[self.navigationController popViewControllerAnimated:YES];
			
			return;
		} else if (indexPath.section == 1) {
			switch (indexPath.row) {
				case 0:
					newVC = [panel getMessages];
					break;
				case 1:
					newVC = [panel getReports];
					break;
				case 2:
					newVC = [panel getHero];
					break;
				case 3:
					newVC = [panel getSettings];
					break;
			}
		} else {
			showsVillage = true;
			[storage.account setVillage:[storage.account.villages objectAtIndex:indexPath.row]];
			currentVillageIndexPath = indexPath;
			[self transitionTableContent:tableView];
			[tableView selectRowAtIndexPath:lastVillageIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			return;
		}
	}
	
	currentViewController = newVC;
	currentViewControllerIndexPath = path;
//	[self.sidePanelController setCenterPanel:newVC];
#warning Something should happen here
}

#pragma mark -

- (void)didBecomeActiveAsPanelAnimated:(BOOL)animated {
	[self.tableView reloadData];
	
	if (!currentViewController) {
		currentViewController = [TMSidePanelViewController sharedInstance].villageOverview;
	}
	if (!currentViewControllerIndexPath) {
		currentViewControllerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	}
	
	[self.tableView selectRowAtIndexPath:currentViewControllerIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

@end
