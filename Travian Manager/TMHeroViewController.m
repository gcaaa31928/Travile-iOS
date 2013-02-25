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

#import "TMHeroViewController.h"
#import "AppDelegate.h"
#import "TMStorage.h"
#import "TMAccount.h"
#import "TMResources.h"
#import "TMHero.h"
#import "TMHeroQuest.h"

@interface TMHeroViewController () {
	TMHero *hero;
	bool viewingMoreQuests;
}

@end

@implementation TMHeroViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[self tableView] setBackgroundView:nil];
}

- (void)viewDidUnload
{
	hero = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	hero = [[TMStorage sharedStorage] account].hero;
	viewingMoreQuests = false;
	
	[self.tabBarController.navigationItem setRightBarButtonItems:nil];
	[self.tabBarController.navigationItem setLeftBarButtonItems:nil];
	[self.tabBarController.navigationItem setRightBarButtonItem:nil];
	[self.tabBarController.navigationItem setLeftBarButtonItem:nil];
	
	[self.tabBarController setTitle:[NSString stringWithFormat:@"Hero"]];
	
	[self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	int qsc = 0;
	TMResources *rpb; // ResourceProductionBoost [hero]
	switch (section) {
		case 0:
			// Facts
			return 4;
		case 1:
			// Attributes
			return 4;
		case 2:
			// Adventures
			qsc = [[hero quests] count];
			//return viewingMoreQuests ? qsc+1 : qsc >= 3 ? 4 : qsc+1;
			//return viewingMoreQuests ? qsc+1 : qsc < 4 ? qsc : qsc+1;
			
			if (viewingMoreQuests)
				return qsc+1; // Quests + button
			else if (qsc == 0)
				return 1; // Label showing no adventures
			else if (qsc < 4)
				return qsc; // Quests
			else if (qsc > 3)
				return 4; // Quests + button
			else
				return qsc+1;
		case 3:
			// Resources
			rpb = [hero resourceProductionBoost];
			
			if (rpb.wood != 0.0f)
				qsc++;
			if (rpb.clay != 0.0f)
				qsc++;
			if (rpb.iron != 0.0f)
				qsc++;
			if (rpb.wheat != 0.0f)
				qsc++;
			
			return qsc;
	}
	
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	int qsc = 0;
	switch (indexPath.section) {
		case 0:
			// Facts
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Hero hiding";
					cell.detailTextLabel.text = [hero isHidden] ? @"YES" : @"NO";
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Experience";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [hero experience]];
					break;
				case 2:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Speed";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [hero speed]];
					break;
				case 3:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Health";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [hero health]];
					break;
			}
			break;
		case 1:
			// Attributes
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Strength";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [hero strengthPoints]];
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Off Bonus";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d%%", [hero offBonusPercentage]];
					break;
				case 2:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Def Bonus";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d%%", [hero defBonusPercentage]];
					break;
				case 3:
					cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
					cell.textLabel.text = @"Resource Bonus pts";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [hero resourceProductionPoints]];
					break;
			}
			break;
		case 2:
			// Adventures
			qsc = [[hero quests] count];
			
			if (qsc == 0) {
				cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
				cell.textLabel.text = @"No adventures";
			} else if (indexPath.row+1 == (viewingMoreQuests ? qsc+1 : 4)) {
				// Button comes last
				cell = [tableView dequeueReusableCellWithIdentifier:@"BasicSelectableCell"];
				cell.textLabel.text = viewingMoreQuests ? @"View less" : [NSString stringWithFormat:@"View more (%d total)", qsc];
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:@"BasicSelectableCell"];
				NSString *difficulty = @"Normal";
				TMHeroQuest *quest = [[hero quests] objectAtIndex:indexPath.row];
				if ([quest difficulty] == QD_VERY_HARD)
					difficulty = @"VHard";
				
				cell.textLabel.text = [NSString stringWithFormat:@"[%@] %ds", difficulty, [quest duration]];
			}
			
			break;
		case 3:
			// Resources boost
			cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell"];
			NSString *tL = @"", *dL = @""; // textLabel, detailLabel
			TMResources *r = [hero resourceProductionBoost];
			
			// Beware tricky fall-through switch logic in place
			switch (indexPath.row) {
				case 0:
					if (r.wood != 0.0f) {
						tL = @"Wood";
						dL = [NSString stringWithFormat:@"%.0f", r.wood];
						break;
					}
				case 1:
					if (r.clay != 0.0f) {
						tL = @"Clay";
						dL = [NSString stringWithFormat:@"%.0f", r.clay];
						break;
					}
				case 2:
					if (r.iron != 0.0f) {
						tL = @"Iron";
						dL = [NSString stringWithFormat:@"%.0f", r.iron];
						break;
					}
				case 3:
					if (r.wheat != 0.0f) {
						tL = @"Wheat";
						dL = [NSString stringWithFormat:@"%.0f", r.wheat];
						break;
					}
			}
			
			cell.textLabel.text = tL;
			cell.detailTextLabel.text = dL;
			
			break;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Facts";
		case 1:
			return @"Attributes";
		case 2:
			return @"Adventures";
		case 3:
			return @"Resources boost";
	}
	
	return @"";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 2) {
		// Check if adventure click or View More button
		int qsc = [[hero quests] count];
		if (indexPath.row+1 == (viewingMoreQuests ? qsc+1 : qsc >= 3 ? 4 : qsc+1)) {
			// View More button click
			if (viewingMoreQuests) {
				// View less
				viewingMoreQuests = false;
				[tableView reloadData];
			} else {
				// view more
				viewingMoreQuests = true;
				[tableView reloadData];
			}
		} else {
			// Start an adventure
			TMAccount *a = [TMStorage sharedStorage].account;
			[[[hero quests] objectAtIndex:indexPath.row] startQuest:a];
			
			NSMutableArray *ar = [[hero quests] mutableCopy];
			[ar removeObjectAtIndex:indexPath.row];
			[hero setQuests:[ar copy]];
			
			[tableView reloadData];
		}
	}
}

@end