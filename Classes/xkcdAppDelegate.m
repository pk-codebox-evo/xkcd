//
//  xkcdAppDelegate.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 8/25/09.
//  Copyright Treeline Labs 2009. All rights reserved.
//

#import "xkcdAppDelegate.h"
#import "ComicListViewController.h"
#import "NSString_HTML.h"
#import "TLMacros.h"
#import "Comic.h"

#define kUserDefaultsRotateKey @"rotate"
#define kUserDefaultsOpenZoomedOutKey @"zoomed_out"
#define kUserDefaultsAutodownloadKey @"autodownload"
#define kUserDefaultsOpenAfterDownloadKey @"autoopen"

#pragma mark -

static NSString *applicationDocumentsDirectory = nil;

#pragma mark -

@interface xkcdAppDelegate ()

@property(nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

#pragma mark -

@implementation xkcdAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  ComicListViewController *listViewController = [[ComicListViewController alloc] initWithStyle:UITableViewStylePlain];

  BOOL canLaunchApplication = YES;
  if(launchOptions) {
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if([launchURL scheme] != @"xkcd") {
      canLaunchApplication = NO;
    }
    NSInteger launchedComic = [[launchURL host] integerValue];
    if(launchedComic > 0) {
      listViewController.requestedLaunchComic = launchedComic;
    }
  }
  
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:listViewController];
  navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;

  window.rootViewController = navigationController;
  [window addSubview:navigationController.view];
  [window makeKeyAndVisible];
  [self performSelector:@selector(setUpLocalNotifications) withObject:nil afterDelay:0.0f];

  return canLaunchApplication;
}

- (UILocalNotification *)weeklyLocalNotification {
  
}

- (void)setUpLocalNotifications {
  NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];

  NSDate *now = [NSDate date];
  NSDateComponents *nowComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit)
                                                fromDate:now];

  NSDateComponents *nextWeekdayComponents = [[NSDateComponents alloc] init];
  nextWeekdayComponents.year = nowComponents.year;
  nextWeekdayComponents.month = nowComponents.month;
  nextWeekdayComponents.weekdayOrdinal = 0;

  UILocalNotification *monday = [[UILocalNotification alloc] init];
  monday.fireDate = [NSDate ];




  // Get the current date
  NSDate *pickerDate = [self.datePicker date];

  // Break the date up into components
  NSDateComponents *dateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit )
                                                 fromDate:pickerDate];
  NSDateComponents *timeComponents = [calendar components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit )
                                                 fromDate:pickerDate];
  // Set up the fire time
  [dateComps setDay:[dateComponents day]];
  [dateComps setMonth:[dateComponents month]];
  [dateComps setYear:[dateComponents year]];
  [dateComps setHour:[timeComponents hour]];
	// Notification will fire in one minute
  [dateComps setMinute:[timeComponents minute]];
	[dateComps setSecond:[timeComponents second]];
  NSDate *itemDate = [calendar dateFromComponents:dateComps];
  [dateComps release];

  UILocalNotification *localNotif = [[UILocalNotification alloc] init];
  if (localNotif == nil)
    return;
  localNotif.fireDate = itemDate;
  localNotif.timeZone = [NSTimeZone defaultTimeZone];

	// Notification details
  localNotif.alertBody = [eventText text];
	// Set the action button
  localNotif.alertAction = @"View";

  localNotif.soundName = UILocalNotificationDefaultSoundName;
  localNotif.applicationIconBadgeNumber = 1;

	// Specify custom data for the notification
  NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
  localNotif.userInfo = infoDict;

	// Schedule the notification
  [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
  [localNotif release];

	[self.tableview reloadData];
}
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];

  NSError *error = nil;
  if(managedObjectContext) {
    if([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			exit(-1);  // Fail
    } 
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [Comic synchronizeDownloadedImages];
}

#pragma mark -
#pragma mark UserDefaults access

- (BOOL)rotate {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsRotateKey]) {
    [self.userDefaults setBool:YES forKey:kUserDefaultsRotateKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsRotateKey];
}

- (BOOL)openZoomedOut {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsOpenZoomedOutKey]) {
    [self.userDefaults setBool:NO forKey:kUserDefaultsOpenZoomedOutKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsOpenZoomedOutKey];
}

- (BOOL)downloadNewComics {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsAutodownloadKey]) {
    [self.userDefaults setBool:NO forKey:kUserDefaultsAutodownloadKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsAutodownloadKey];
}

- (BOOL)openAfterDownload {
  if(![[self.userDefaults dictionaryRepresentation] objectForKey:kUserDefaultsOpenAfterDownloadKey]) {
    [self.userDefaults setBool:YES forKey:kUserDefaultsOpenAfterDownloadKey];
    [self.userDefaults synchronize];
  }
  return [self.userDefaults boolForKey:kUserDefaultsOpenAfterDownloadKey];
}

- (NSUserDefaults *)userDefaults {
  if(!userDefaults) {
    userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
  }
  return userDefaults;
}

#pragma mark -
#pragma mark Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (void)save {
  NSError *error = nil;
  if(![[self managedObjectContext] save:&error]) {
    TLDebugLog(@"SAVE FAILED %@", error);
  }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
  if (managedObjectContext != nil) {
    return managedObjectContext;
  }
	
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if(coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  
  [managedObjectContext setUndoManager:nil];
  
  return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
  if (managedObjectModel != nil) {
    return managedObjectModel;
  }
  managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
  return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  if (persistentStoreCoordinator != nil) {
    return persistentStoreCoordinator;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];

  // Clean up the old file from previous versions
  NSString *oldStorePath = [self.applicationDocumentsDirectory stringByAppendingPathComponent: @"xkcd.sqlite"];
  if([fileManager fileExistsAtPath:oldStorePath]) {
    NSError *removalError = nil;
    [fileManager removeItemAtPath:oldStorePath error:&removalError];
    if(removalError) {
      TLDebugLog(@"Error removing old sqlite file at %@", removalError);
    }
  }

  NSString *storePath = [self.applicationDocumentsDirectory stringByAppendingPathComponent: @"comics.sqlite"];
  TLDebugLog(@"Store path: %@", [storePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]);
  
  if(![fileManager fileExistsAtPath:storePath]) {
    NSString *bundledPath = [[NSBundle mainBundle] pathForResource:@"comics" ofType:@"sqlite"];
    if([fileManager fileExistsAtPath:bundledPath]) {
      [fileManager copyItemAtPath:bundledPath toPath:storePath error:NULL];
    }
  }
  
  NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	NSError *error = nil;
  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
  if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                               configuration:nil
                                                         URL:storeUrl
                                                     options:nil
                                                       error:&error]) {
    NSLog(@"Error opening store: %@", error);
  }
	
  return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 Memo-ized to provide faster delete-all + download-all functionality.
 */
- (NSString *)applicationDocumentsDirectory {
  if(!applicationDocumentsDirectory) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if(basePath) {
      applicationDocumentsDirectory = basePath;
    }
  }
  return applicationDocumentsDirectory;
}

@end

