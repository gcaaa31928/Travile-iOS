/* Copyright (C) 2011 - 2013 Matej Kramny <matejkramny@gmail.com>
 * All rights reserved.
 */

#import "TMAccountsViewController.h"
#import "TMStorage.h"
#import "TMAccount.h"
#import "TMAccountDetailsViewController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

@interface TMAccountsViewController () {
	TMStorage *storage;
	TMAccount *selectedAccount;
	UIAlertView *passwordPromptView;
	UIAlertView *passwordRetryView;
	TMAccount *passwordRetryAccount;
	MBProgressHUD *hud;
	UITapGestureRecognizer *tapGestureRecognizer;
	bool firstAnimateButtons;
	
	// Analytics - waiting for loading interval
	int startedLoadingUNIXTime;
	
	bool insideSettings;
	
	UIBarButtonItem *addButton;
	UIBarButtonItem *editButton;
	UIBarButtonItem *editButtonDone;
	UIBarButtonItem *settingsButton;
	
	bool canSkipLoading;
}

- (void)logIn:(TMAccount *)a withPasword:(NSString *)password;
- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)recognizer;

@end

@interface TMAccountsViewController (ActionButtons)

- (void)editButtonClicked:(id)sender;
- (void)addAccount:(id)sender;
- (void)dismissView;

@end

@implementation TMAccountsViewController (ActionButtons)

- (void)editButtonClicked:(id)sender {
	if ([storage.accounts count] > 0 || [self isEditing])
		[self setEditing:![self isEditing] animated:YES];
}

- (void)addAccount:(id)sender {
	selectedAccount = nil;
	[self performSegueWithIdentifier:@"NewAccount" sender:self];
}

- (void)showSettings:(id)sender {
	[self performSegueWithIdentifier:@"OpenSettings" sender:self];
}

// Overrides setEditing messages to change buttons on Navigation Bar
- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:NO];
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	
	if (editing) {
		[self.navigationItem setLeftBarButtonItem:editButtonDone animated:animated];
		[self.navigationItem setRightBarButtonItem:settingsButton animated:animated];
	} else if ([storage.accounts count] > 0) {
		[self.navigationItem setLeftBarButtonItem:editButton animated:animated];
		[self.navigationItem setRightBarButtonItem:addButton animated:animated];
	} else {
		[self.navigationItem setLeftBarButtonItem:nil];
		[self.navigationItem setRightBarButtonItem:addButton animated:animated];
	}
}

- (void)dismissView {
	[self performSegueWithIdentifier:@"OpenAccount" sender:self];
}

@end

@implementation TMAccountsViewController

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
	storage = [TMStorage sharedStorage];
	
	firstAnimateButtons = false;
	
	addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccount:)];
	editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonClicked:)];
	editButtonDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editButtonClicked:)];
	settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
	
	insideSettings = false;
	canSkipLoading = false;
	
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	if (firstAnimateButtons == false) {
		// Do not fade buttons in, happens when returning from NewAccount scene
		if ([[storage accounts] count] == 0) {
			[self.navigationItem setLeftBarButtonItem:nil];
		} else {
			[self.navigationItem setLeftBarButtonItem:editButton animated:NO];
		}
		
		[self.navigationItem setRightBarButtonItem:addButton animated:NO];
	}
	
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	if (indexPath != nil) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	
	if (insideSettings) {
		[self setEditing:NO animated:NO];
	}
	
	[self.navigationItem setTitle:NSLocalizedString(@"Accounts", nil)];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	canSkipLoading = false;
}

- (void)viewDidAppear:(BOOL)animated {
	if (firstAnimateButtons) {
		// Fades the buttons in, after logging out from an account.
		if ([[storage accounts] count] == 0) {
			[self.navigationItem setLeftBarButtonItem:nil];
		} else {
			[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonClicked:)] animated:YES];
		}
		
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccount:)] animated:YES];
		
		firstAnimateButtons = false;
	}
	
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	
	[super viewDidAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	return [[storage accounts] count] == 0 ? 1 : [[storage accounts] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"AccountCell";
	static NSString *AddAccountImageIndicatorCell = @"AddAccountImage";
	
	UITableViewCell *cell;
	if ([[storage accounts] count] == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:AddAccountImageIndicatorCell];
		[cell setOpaque:YES];
		[cell setAlpha:1];
		
		[AppDelegate setCellAppearance:cell forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

		// Configure the cell...
		TMAccount *a = [[storage accounts] objectAtIndex:indexPath.row];
		cell.textLabel.text = [a name];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@@%@.travian.%@%@", a.username, a.world, a.server, DEBUG ? @"!-DEBUG" : @""];

		[cell setOpaque:YES];
		[cell setAlpha:1];

		[AppDelegate setCellAppearance:cell forIndexPath:indexPath];
	}
	
	return cell;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	// Move the account in the array
	NSMutableArray *arr = [storage.accounts mutableCopy];
	TMAccount *a = [arr objectAtIndex:fromIndexPath.row];
	[arr removeObjectAtIndex:fromIndexPath.row];
	[arr insertObject:a atIndex:toIndexPath.row];
	storage.accounts = [arr copy];
}

- (void)logIn:(TMAccount *)a withPasword:(NSString *)password {
	// start counting...
	startedLoadingUNIXTime = [[NSDate date] timeIntervalSince1970];
	
	// Check if we need to be prompted for password
	
	// Activate the account
	[storage setActiveAccount:a withPassword:password];
	[[storage account] addObserver:self forKeyPath:@"notificationPending" options:NSKeyValueObservingOptionNew context:NULL]; // Notification pending bool
	[[storage account] addObserver:self forKeyPath:@"progressIndicator" options:NSKeyValueObservingOptionNew context:NULL]; // Progress Indication for HUD
	[[storage account] addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL]; // Watch for account status
	
	hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	hud.labelText = NSLocalizedString(@"Logging In", @"");
	hud.detailsLabelText = NSLocalizedString(@"Tap to cancel", @"Shown in HUD, informative to cancel the operation");
	hud.dimBackground = YES;
	
	// Cancel tap Gesture recognizer
	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
	[tapGestureRecognizer setNumberOfTapsRequired:1];
	[tapGestureRecognizer setNumberOfTouchesRequired:1];
	[hud addGestureRecognizer:tapGestureRecognizer];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)recognizer {
	if (canSkipLoading) {
		[hud hide:YES];
		
		[storage.account removeObserver:self forKeyPath:@"notificationPending"];
		[storage.account removeObserver:self forKeyPath:@"progressIndicator"];
		[storage.account removeObserver:self forKeyPath:@"status"];
		
		[[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
		
		[self dismissView];
		canSkipLoading = false;
		
		return;
	}
	
	[hud hide:YES];
	[hud removeGestureRecognizer:tapGestureRecognizer];
	tapGestureRecognizer = nil;
	
	[storage.account removeObserver:self forKeyPath:@"notificationPending"];
	[storage.account removeObserver:self forKeyPath:@"progressIndicator"];
	[storage.account removeObserver:self forKeyPath:@"status"];
	
	[storage deactivateActiveAccount];
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([storage.accounts count] == 0) {
		[self performSegueWithIdentifier:@"NewAccount" sender:self];
		return;
	}
	
	selectedAccount = [storage.accounts objectAtIndex:indexPath.row];
	
	if ([self isEditing])
	{
		// Editing account
		[self performSegueWithIdentifier:@"NewAccount" sender:self];
	}
	else
	{
		// Open selected account
		TMAccount *a = [[storage accounts] objectAtIndex:indexPath.row];
		
		if ([[a password] length] == 0) {
			passwordPromptView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Password required", @"Title of popup displayed when there is no password during login") message:[NSString stringWithFormat:NSLocalizedString(@"Please enter password for account %@", @"Prompts the user to enter password"), [a name]] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Continue", nil), nil];
			[passwordPromptView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
			[passwordPromptView show];
			
			return;
		}
		
		[self logIn:a withPasword:[a password]];
	}
}

#pragma mark - Key-Value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"notificationPending"]) {
		NSNumber *n = [change objectForKey:NSKeyValueChangeNewKey];
		if ([n boolValue] == YES) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notification pending", @"Title of popup when there is a notification pending") message:NSLocalizedString(@"There is a Travian notification pending review.", @"Text of popup when there is a notification pending") delegate:self cancelButtonTitle:NSLocalizedString(@"Continue", nil) otherButtonTitles:NSLocalizedString(@"View", nil), nil];
			[alert show];
		}
	} else if ([keyPath isEqualToString:@"progressIndicator"]) {
		// Shows progress
		hud.labelText = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (selectedAccount.villages.count > 0) {
			// Enable to hide the loading and continue
			canSkipLoading = true;
			hud.detailsLabelText = NSLocalizedString(@"Logged in. Tap to continue", @"Shown after the user is logged in");
		}
	} else if ([keyPath isEqualToString:@"status"]) {
		// Checks for change of account status
		AccountStatus stat = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
		if ((stat & AConnectionFailed) != 0) {
			// The connection failed
			hud.labelText = NSLocalizedString(@"Connection failed", @"Shown on HUD when the connection fails");
			hud.detailsLabelText = NSLocalizedString(@"Tap to dismiss.", nil);
			/// TODO Show big X (image)
		} else if ((stat & (ACannotLogIn)) != 0) {
			// Cannot log in.
			// Display Alert - Cancel - Retry with new password
			
			if ([storage.account password].length > 0) {
				//[tracker sendEventWithCategory:@"failed_login" withAction:@"prompt password" withLabel:@"cannot login" withValue:[NSNumber numberWithInt:10]];
			} else {
				// Nil password - user wants to enter his pwd for security
				//[tracker sendEventWithCategory:@"security" withAction:@"prompt" withLabel:@"enter password" withValue:[NSNumber numberWithInt:10]];
			}
			
			[storage.account removeObserver:self forKeyPath:@"notificationPending"];
			[storage.account removeObserver:self forKeyPath:@"progressIndicator"];
			[storage.account removeObserver:self forKeyPath:@"status"];
			[hud hide:YES];
			[hud removeGestureRecognizer:tapGestureRecognizer];
			tapGestureRecognizer = nil;
			
			passwordRetryAccount = storage.account;
			passwordRetryView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot log in", @"Shown as title of popup when the app cannot log the user in") message:NSLocalizedString(@"TM cannot log in. Enter your password to retry.", @"Shown as text of popup when the password is incorrect during login") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Retry", nil), nil];
			[passwordRetryView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
			[passwordRetryView show];
		} else if ((stat & ARefreshed) != 0) {
			// Finished loading
			
			// Record this with Analytics (time it took)
			//int diff = [[NSDate date] timeIntervalSince1970] - startedLoadingUNIXTime;
			startedLoadingUNIXTime = 0;
			//[tracker sendTimingWithCategory:@"resources" withValue:diff withName:@"login" withLabel:nil];
			
			[hud setLabelText:NSLocalizedString(@"Done", @"Shown on HUD when the app finishes logging in. Shown with a big Tick picture..")];
			[hud setDetailsLabelText:@""];
			[hud removeGestureRecognizer:tapGestureRecognizer];
			tapGestureRecognizer = nil;
			[hud setCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]]];
			[hud setMode:MBProgressHUDModeCustomView];
			
			[hud hide:YES afterDelay:0.6];
			
			[storage.account removeObserver:self forKeyPath:@"notificationPending"];
			[storage.account removeObserver:self forKeyPath:@"progressIndicator"];
			[storage.account removeObserver:self forKeyPath:@"status"];
			
			//[[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
			
			[self performSelector:@selector(dismissView) withObject:self afterDelay:0.6];
		}
	}
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == passwordPromptView) {
		if (buttonIndex == 0) {
			[[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
		} else {
			[self logIn:[[storage accounts] objectAtIndex:[[self tableView] indexPathForSelectedRow].row] withPasword:[[alertView textFieldAtIndex:0] text]];
		}
		return;
	} else if (alertView == passwordRetryView) {
		if (buttonIndex == 0) {
			[[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
		}
		else {
			[self logIn:passwordRetryAccount withPasword:[[alertView textFieldAtIndex:0] text]];
		}
		
		return;
	}
	
	//[[storage account] removeObserver:self forKeyPath:@"notificationPending"];
	
	if (buttonIndex == 1) {
		// View
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.travian.%@/dorf1.php", [[storage account] world], [[storage account] server]]];
		[[UIApplication sharedApplication] openURL:url];
		// Cancel log in
		[hud hide:YES];
		
		[storage.account removeObserver:self forKeyPath:@"notificationPending"];
		[storage.account removeObserver:self forKeyPath:@"progressIndicator"];
		[storage.account removeObserver:self forKeyPath:@"status"];
		
		[[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:YES];
	} else if (buttonIndex == 0) {
		// Proceed
		[[storage account] skipNotification];
	}
}

#pragma mark - prepareForSegue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"NewAccount"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		TMAccountDetailsViewController *advc = [[navigationController viewControllers] objectAtIndex:0];
		
		advc.delegate = self;
		advc.editingAccount = selectedAccount;
	} else {
		insideSettings = true;
	}
}

#pragma mark - PHAccountDetailsViewControllerDelegate

- (void)accountDetailsViewController:(TMAccountDetailsViewController *)controller didAddAccount:(TMAccount *)account
{
	// Add the account
	if (storage.accounts == nil)
		storage.accounts = [[NSArray alloc] init];
	storage.accounts = [storage.accounts arrayByAddingObject:account];
	
	// Dismiss the view
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if ([storage.accounts count]-1 == 0) {
		// First account created..
		[self.tableView reloadData];
	} else {
		// Tell table to add row
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[storage.accounts count] - 1 inSection:0];
		[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
	}
	
	selectedAccount = nil;
	[self setEditing:NO];
	
	[storage saveData];
}
- (void)accountDetailsViewController:(TMAccountDetailsViewController *)controller didEditAccount:(TMAccount *)oldAccount
{
	// Dismiss view
	[self dismissViewControllerAnimated:YES completion:nil];
	
	selectedAccount = nil;
	[self setEditing:NO];
	
	[self.tableView reloadData];
	
	[storage saveData];
}
- (void)accountDetailsViewControllerDidCancel:(TMAccountDetailsViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	selectedAccount = nil;
	[self setEditing:NO];
}
- (void)accountDetailsViewController:(TMAccountDetailsViewController *)controller didDeleteAccount:(TMAccount *)account {
	int location = [storage.accounts indexOfObjectIdenticalTo:account];
	if(location != NSNotFound)
	{
		// Replace old account with new
		NSMutableArray *arr = [storage.accounts mutableCopy];
		[arr removeObjectAtIndex:location];
		storage.accounts = [arr copy];
		
		// Reload table source
		[self.tableView reloadData];
	}
	
	[self setEditing:NO];
	selectedAccount = nil;
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.tableView reloadData];
	
	[storage saveData];
}

@end
