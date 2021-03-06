//
//  BookmarksViewController.m
//  iCPAN
//
//  Created by WunderSolutions.com on 10-03-15.
//  Copyright 2010 WunderSolutions.com. All rights reserved.
//

#import "BookmarksViewController.h"
#import "MasterViewController.h"
#import "Module.h"
#import "Author.h"
#import "ModuleTableViewCell.h"
#import "iCPANAppDelegate.h"


@implementation BookmarksViewController

@synthesize fetchedResultsController, managedObjectContext;


- (void)viewWillAppear:(BOOL)animated {
	
	iCPANAppDelegate *appDelegate = (iCPANAppDelegate*)[[UIApplication sharedApplication] delegate];
	NSDictionary *bookmarks = appDelegate.getBookmarks;
	
	if( bookmarks.count == 0 ) {
		[self.tableView reloadData];
		self.navigationItem.rightBarButtonItem = nil;
		return;
	}

	self.tableView.scrollEnabled = YES;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
	// get the contex object -- for some reason it the order of loading of our files is causing this
    // implementation to load before the AppDelegate, so pushing the context into here doesn't work.
    if (managedObjectContext == nil) 
    { 
        self.managedObjectContext = [(iCPANAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]; 
    }
    
    NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Replace this implementation with code to handle the error appropriately.
        
		//NSLog(@"fetchedResultsController error %@, %@", error, [error userInfo]);
		exit(1);
	}

	[self.tableView reloadData];

}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    // Set up the fetched results controller if needed.
	// Am creating a new controller each time so that the bookmarks list is refreshed every time the
	// page is viewed.  
    iCPANAppDelegate *appDelegate = (iCPANAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSDictionary *bookmarks = appDelegate.getBookmarks;
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Module" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];        
    [fetchRequest setFetchBatchSize:20];
    if([bookmarks count]) {
        NSString *attributeName = @"name";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN[cd] %@", attributeName, [bookmarks allValues]];
        [fetchRequest setPredicate:predicate];
    }
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [sortDescriptors release];
    [sortDescriptor release];
    [fetchRequest release];
    
	return fetchedResultsController;
}


# pragma mark -
# pragma mark UITableView data source and delegate methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    	
	iCPANAppDelegate *appDelegate = (iCPANAppDelegate*)[[UIApplication sharedApplication] delegate];
	NSDictionary *bookmarks = appDelegate.getBookmarks;
	
	return bookmarks.count;
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
    static NSString *kCellID = @"cellID";

    ModuleTableViewCell *cell = (ModuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kCellID];
    if (cell == nil) {
        cell = [[[ModuleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	[self configureCell:cell atIndexPath:indexPath];
    
    return cell;

}


- (void)configureCell:(ModuleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
	Module *module = (Module *)[fetchedResultsController objectAtIndexPath:indexPath];
    cell.module = module;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    MasterViewController *bookmarksViewController = [[MasterViewController alloc] init];
    
    Module *module = nil;
    module = (Module *)[fetchedResultsController objectAtIndexPath:indexPath];
        
	bookmarksViewController.hidesBottomBarWhenPushed = YES;
	
	iCPANAppDelegate *appDelegate = (iCPANAppDelegate*)[[UIApplication sharedApplication] delegate];
	appDelegate.selectedModule = module;
	
    [[self navigationController] pushViewController:bookmarksViewController animated:YES];
    [bookmarksViewController release];
    
}

 
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {

		iCPANAppDelegate *appDelegate = (iCPANAppDelegate*)[[UIApplication sharedApplication] delegate];
		NSDictionary *bookmarks = appDelegate.getBookmarks;
		
		NSMutableDictionary *mutable_bookmarks = [[bookmarks mutableCopy] autorelease];
		Module *module = (Module *)[fetchedResultsController objectAtIndexPath:indexPath];

		[mutable_bookmarks removeObjectForKey:module.name];
		
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

		[prefs setObject:mutable_bookmarks forKey:@"bookmarks"];
		[prefs synchronize];
		
		//NSLog(@"mod  name: %@", module.name);
				
		// this always throws an error
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
						 withRowAnimation:UITableViewRowAnimationFade]; 
		
	}
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;

    self.fetchedResultsController = nil;
}


- (void)dealloc {
	[fetchedResultsController release];
	[managedObjectContext release];
    
    [super dealloc];
}

@end
