////////////////////////////////////////////////////////////////////////////
//
// This software contains code derived from RealmExamples:
// Portions Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "MRViewController.h"
#import <Realm/Realm.h>

#import "MRRealmResultsController.h"


@interface DemoObject : RLMObject

@property NSString  *title;
@property NSDate    *date;
@property NSString  *dateString;
@property NSString  *timeString;
@property NSString  *yearString;
@property NSString  *monthString;
@property NSString  *dayString;
@property NSData    *data;

@end


@implementation DemoObject

+ (NSString *)primaryKey
{
    return @"title";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{ @"data": NSData.data };
}

@end


#pragma mark -
#pragma mark -


@interface MRViewController () <MRRealmResultsControllerDelegate> {
    NSInteger _count;
    BOOL _displaySections;
    BOOL _sortDays;
}
@property (nonatomic, strong) MRRealmResultsController *resultsController;
@end


@implementation MRViewController

- (void)resetResultsController
{
    NSPredicate *const predicate = [NSPredicate predicateWithFormat:@"date > %@", NSDate.date];
    NSSortDescriptor *sortDescriptor;
    NSSortDescriptor *sectionSortDescriptor;
    if (_sortDays) {
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dayString" ascending:NO];
        sectionSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"yearString" ascending:YES];
    }
    if (_displaySections) {
        self.resultsController =
        [[MRRealmResultsController alloc] initWithClass:DemoObject.class
                                              predicate:predicate
                                                  realm:nil
                                         sortDescriptor:sortDescriptor
                                  sectionSortDescriptor:sectionSortDescriptor
                                         andNameKeyPath:@"yearString"];
    } else {
        self.resultsController =
        [[MRRealmResultsController alloc] initWithClass:DemoObject.class
                                              predicate:predicate
                                                  realm:nil
                                         sortDescriptor:sortDescriptor
                                  sectionSortDescriptor:nil
                                         andNameKeyPath:nil];
    }
    self.resultsController.delegate = self;
    [self.resultsController performFetch];
    [self.tableView reloadData];
}

- (NSString *)randomString
{
    return [NSString stringWithFormat:@"Title %d", arc4random()%50000];
}

- (NSDate *)randomDate
{
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

- (DemoObject *)createDemoObjectInCurrentTransaction:(RLMRealm *const)realm
{
    NSDate *const randomDate = self.randomDate;
    NSArray *const words = [randomDate.description componentsSeparatedByString:@" "];
    NSString *const dateString = words[0];
    NSString *const timeString = words[1];
    NSDateComponents *const components =
    [NSCalendar.currentCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:randomDate];
    NSString *const yearString = @(components.year).stringValue;
    NSString *const monthString = @(components.month).stringValue;
    NSString *const dayString = @(components.day).stringValue;
    
    NSDictionary *const dict = @{ @"title": self.randomString,
                                  @"date": randomDate,
                                  @"dateString": dateString,
                                  @"timeString": timeString,
                                  @"yearString": yearString,
                                  @"monthString": monthString,
                                  @"dayString": dayString };
    
    return [DemoObject createOrUpdateInRealm:realm withObject:dict];
}

#pragma mark - IB actions

- (IBAction)toggleSort:(UIButton *)sender
{
    _sortDays = !_sortDays;
    if (_sortDays) {
        sender.tintColor = UIColor.greenColor;
    } else {
        sender.tintColor = UIColor.redColor;
    }
    [self resetResultsController];
}

- (IBAction)toggleSections:(UIButton *)sender
{
    _displaySections = !_displaySections;
    if (_displaySections) {
        sender.tintColor = UIColor.greenColor;
    } else {
        sender.tintColor = UIColor.redColor;
    }
    [self resetResultsController];
}

- (IBAction)backgroundAdd
{
    static NSInteger const INSERT_COUNT = 5;
    _count += INSERT_COUNT;

    self.label.textColor = UIColor.redColor;
    
    __weak typeof(self) const weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *const realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        for (NSInteger index = 0; index < INSERT_COUNT; index++) {
            [weakSelf createDemoObjectInCurrentTransaction:realm];
        }
        [realm commitWriteTransaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.label.textColor = UIColor.blackColor;
        });
    });
}

- (IBAction)removeAll
{
    _count = 0;
    
    RLMRealm *const realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];
    [realm deleteObjects:DemoObject.allObjects];
    [realm commitWriteTransaction];
}

#pragma mark - MRRealmResultsControllerDelegate

- (void)controllerWillChangeContent:(MRRealmResultsController *const)controller
{
    NSAssert(NSThread.isMainThread, @"not in main thread");
    
    [self.tableView beginUpdates];
}

- (void)controller:(MRRealmResultsController *const)controller
  didChangeSection:(id<MRRealmSectionInfo> const)sectionInfo
           atIndex:(NSUInteger const)sectionIndex
     forChangeType:(MRRealmResultsChangeType const)type
{
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch (type) {
        case MRRealmResultsChangeInsert:
            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case MRRealmResultsChangeDelete:
            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case MRRealmResultsChangeCount:
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(MRRealmResultsController *const)controller
{
    NSAssert(NSThread.isMainThread, @"not in main thread");
    
    [self.tableView endUpdates];
    self.label.text = [NSString stringWithFormat:@"<=%ld in %ld", (long)_count, (long)self.resultsController.sections.count];
    
    // Make sure that visible cells have been reloaded:
    [self.tableView beginUpdates];
    NSArray *const indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows;
    NSArray *const sectionsArray = [indexPathsForVisibleRows valueForKey:@"section"];
    NSSet *sectionsSet = [NSSet setWithArray:sectionsArray];
    for (NSNumber *const sectionNumber in sectionsSet) {
        NSUInteger sectionIndex = sectionNumber.unsignedIntegerValue;
        NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView endUpdates];
}

- (NSString *)controller:(MRRealmResultsController *const)controller sectionIndexTitleForSectionName:(NSString *const)sectionName
{
    if (sectionName.length == 0) {
        return sectionName;
    } if (sectionName.length == 1) {
        return sectionName.uppercaseString;
    } else {
        return [sectionName substringFromIndex:sectionName.length - 2].uppercaseString;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *const)tableView
{
    return self.resultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *const)tableView numberOfRowsInSection:(NSInteger const)section
{
    id<MRRealmSectionInfo> const sectionInfo = self.resultsController.sections[section];
    NSUInteger const numberOfObjects = [sectionInfo numberOfObjects];
    return numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *const)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
    DemoObject *const object = [self.resultsController objectAtIndexPath:indexPath];

    UITableViewCell *cell;
    if (object.monthString.integerValue%2 == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCellStyleSubtitle"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:@"UITableViewCellStyleSubtitle"];
            cell.textLabel.textColor = UIColor.whiteColor;
            cell.detailTextLabel.textColor = UIColor.whiteColor;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCellStyleValue1"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:@"UITableViewCellStyleValue1"];
            cell.textLabel.textColor = UIColor.whiteColor;
            cell.detailTextLabel.textColor = UIColor.whiteColor;
        }
    }

    cell.textLabel.text = object.title;
    cell.detailTextLabel.text = object.dateString.description;
    CGFloat const red = MAX(0.2f, object.monthString.floatValue/12);
    CGFloat const blue = MAX(0.2f, object.dayString.floatValue/31);
    cell.contentView.backgroundColor = [UIColor colorWithRed:red green:blue blue:0.5f alpha:1];
    cell.imageView.image = [UIImage imageWithData:object.data];

    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *const)tableView titleForHeaderInSection:(NSInteger const)section
{
    NSArray *const sections = self.resultsController.sections;
    id<MRRealmSectionInfo> const sectionInfo = sections[section];
    return sectionInfo.name;
}

-  (void)tableView:(UITableView *const)tableView
commitEditingStyle:(UITableViewCellEditingStyle const)editingStyle
 forRowAtIndexPath:(NSIndexPath *const)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DemoObject *const object = [self.resultsController objectAtIndexPath:indexPath];
        RLMRealm *const realm = object.realm;
        [realm beginWriteTransaction];
        [realm deleteObject:object];
        [realm commitWriteTransaction];
    }
}

- (CGFloat)tableView:(UITableView *const)tableView heightForRowAtIndexPath:(NSIndexPath *const)indexPath
{
    DemoObject *const object = [self.resultsController objectAtIndexPath:indexPath];
    if (object.monthString.integerValue%2 == 0) {
        return 54.0f;
    } else {
        return 34.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DemoObject *const object = [self.resultsController objectAtIndexPath:indexPath];
    NSLog(@"====================================");
    NSLog(@"Selected object %@", object);
    NSLog(@"------------------------------------");
    id<MRRealmSectionInfo> const sectionInfo = self.resultsController.sections[indexPath.section];
    NSLog(@"In section:\n%@", sectionInfo.objects);
    NSLog(@"====================================");
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.resultsController sectionForSectionIndexTitleAtIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.resultsController.sectionIndexTitles;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self toggleSections:nil]; // resets results controller
    _count = DemoObject.allObjects.count;
    self.label.text = [NSString stringWithFormat:@"<=%ld in %ld", (long)_count, (long)self.resultsController.sections.count];
}

@end
