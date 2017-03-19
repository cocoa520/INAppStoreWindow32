//
//	INWindowButton.m
//
//	Copyright 2013-2014 Vladislav Alexeev. All rights reserved.
//
//	Licensed under the BSD 2-clause License. See LICENSE file distributed in the source
//	code of this project.
//

#import "INAppStoreWindowCompatibility.h"
#import "INWindowButton.h"

#pragma mark - Window Button Group

NSString *const INWindowButtonGroupDidUpdateRolloverStateNotification = @"INWindowButtonGroupDidUpdateRolloverStateNotification";
NSString *const kINWindowButtonGroupDefault = @"com.indragie.inappstorewindow.defaultWindowButtonGroup";

@interface INWindowButtonGroup : NSObject
{
    NSString * _identifier;
    NSInteger _numberOfCaptures;
}
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, assign) NSInteger numberOfCaptures;

+ (instancetype)groupWithIdentifier:(NSString *)identifier;

- (void)didCaptureMousePointer;
- (void)didReleaseMousePointer;
- (BOOL)shouldDisplayRollOver;

- (void)resetMouseCaptures;

@end

@implementation INWindowButtonGroup
@synthesize identifier = _identifier;
@synthesize numberOfCaptures = _numberOfCaptures;

+ (instancetype)groupWithIdentifier:(NSString *)identifier
{
	static NSMutableDictionary *groups = nil;
	if (groups == nil) {
		groups = [[NSMutableDictionary alloc] init];
	}

	if (identifier == nil) {
		identifier = kINWindowButtonGroupDefault;
	}

	INWindowButtonGroup *group = groups[identifier];
	if (group == nil) {
		group = [[[self class] alloc] initWithIdentifier:identifier];
		groups[identifier] = group;
	}
	return [group autorelease];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super init];
	if (self) {
		_identifier = [identifier copy];
	}
	return self;
}

- (void)dealloc {
    [_identifier release],_identifier = nil;
    [super dealloc];
}

- (void)setNumberOfCaptures:(NSInteger)numberOfCaptures
{
	if (_numberOfCaptures != numberOfCaptures && numberOfCaptures >= 0) {
		_numberOfCaptures = numberOfCaptures;
		[[NSNotificationCenter defaultCenter] postNotificationName:INWindowButtonGroupDidUpdateRolloverStateNotification
															object:self];
	}
}

- (void)didCaptureMousePointer
{
	self.numberOfCaptures++;
}

- (void)didReleaseMousePointer
{
	self.numberOfCaptures--;
}

- (BOOL)shouldDisplayRollOver
{
	return (self.numberOfCaptures > 0);
}

- (void)resetMouseCaptures
{
	self.numberOfCaptures = 0;
}

@end

#pragma mark - Window Button

@interface INWindowButton ()
@property (nonatomic, copy) NSString *groupIdentifier;
@property (nonatomic, retain, readonly) INWindowButtonGroup *group;
@property (nonatomic, retain) NSTrackingArea *mouseTrackingArea;

@end

@implementation INWindowButton
@synthesize groupIdentifier = _groupIdentifier;
@synthesize group = _group;
@synthesize mouseTrackingArea = _mouseTrackingArea;
@synthesize activeImage = _activeImage;
@synthesize activeNotKeyWindowImage = _activeNotKeyWindowImage;
@synthesize inactiveImage = _inactiveImage;
@synthesize rolloverImage = _rolloverImage;
@synthesize pressedImage = _pressedImage;

+ (instancetype)windowButtonWithSize:(NSSize)size groupIdentifier:(NSString *)groupIdentifier
{
	INWindowButton *button = [[self alloc] initWithSize:size groupIdentifier:groupIdentifier];
	return [button autorelease];
}

#pragma mark - Init and Dealloc

- (instancetype)initWithSize:(NSSize)size groupIdentifier:(NSString *)groupIdentifier
{
	self = [super initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
	if (self) {
		_groupIdentifier = [groupIdentifier copy];
		[self setButtonType:NSMomentaryChangeButton];
		[self setBordered:NO];
		[self setTitle:@""];
		[self.cell setHighlightsBy:NSContentsCellMask];
		[self.cell setImageDimsWhenDisabled:NO];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowButtonGroupDidUpdateRolloverStateNotification:) name:INWindowButtonGroupDidUpdateRolloverStateNotification object:self.group];
	}
	return self;
}

- (void)dealloc
{
    [_groupIdentifier release],_groupIdentifier = nil;
    [_group release],_group = nil;
    [_mouseTrackingArea release],_mouseTrackingArea = nil;
    [_activeImage release],_activeImage = nil;
    [_rolloverImage release],_rolloverImage = nil;
    [_inactiveImage release],_inactiveImage = nil;
    [_pressedImage release],_pressedImage = nil;
    [_activeNotKeyWindowImage release],_activeNotKeyWindowImage = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark - Group

- (INWindowButtonGroup *)group
{
	return [INWindowButtonGroup groupWithIdentifier:self.groupIdentifier];
}

- (void)windowButtonGroupDidUpdateRolloverStateNotification:(NSNotification *)n
{
	[self updateRollOverImage];
}

#pragma mark - Tracking Area

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];

	if (self.mouseTrackingArea) {
		[self removeTrackingArea:self.mouseTrackingArea];
	}

    NSTrackingArea *mouseTrackingArea = [[[NSTrackingArea alloc] initWithRect:NSInsetRect(self.bounds, -4, -4)
                                                                      options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                                        owner:self
                                                                     userInfo:nil] autorelease];

	[self addTrackingArea:self.mouseTrackingArea = mouseTrackingArea];
}

#pragma mark - Window State Handling

- (void)viewDidMoveToWindow
{
	if (self.window) {
		[self updateImage];
	}
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (self.window) {
		[nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
		[nc removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
		[nc removeObserver:self name:NSWindowDidMiniaturizeNotification object:self.window];
		if ([NSWindow instancesRespondToSelector:@selector(toggleFullScreen:)]) {
			[nc removeObserver:self name:NSWindowWillEnterFullScreenNotification object:self.window];
			[nc removeObserver:self name:NSWindowWillExitFullScreenNotification object:self.window];
		}
	}
	if (newWindow != nil) {
		[nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidBecomeKeyNotification object:newWindow];
		[nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidResignKeyNotification object:newWindow];
		[nc addObserver:self selector:@selector(windowDidMiniaturize:) name:NSWindowDidMiniaturizeNotification object:newWindow];
		if ([NSWindow instancesRespondToSelector:@selector(toggleFullScreen:)]) {
			[nc addObserver:self selector:@selector(windowWillEnterFullScreen:) name:NSWindowWillEnterFullScreenNotification object:newWindow];
			[nc addObserver:self selector:@selector(windowWillExitFullScreen:) name:NSWindowWillExitFullScreenNotification object:newWindow];
		}
	}
}

- (void)windowDidChangeFocus:(NSNotification *)n
{
	[self updateImage];
}

- (void)windowWillEnterFullScreen:(NSNotification *)n
{
	[self.group resetMouseCaptures];
	self.hidden = YES;
}

- (void)windowWillExitFullScreen:(NSNotification *)n
{
	[self.group resetMouseCaptures];
	self.hidden = NO;
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
	[self.group resetMouseCaptures];
}

#pragma mark - Event Handling

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	[self.group resetMouseCaptures];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[super mouseEntered:theEvent];
	[self.group didCaptureMousePointer];
	[self updateRollOverImage];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[super mouseExited:theEvent];
	[self.group didReleaseMousePointer];
	[self updateRollOverImage];
}

#pragma mark - Button Appearance

- (void)setPressedImage:(NSImage *)pressedImage
{
	self.alternateImage = pressedImage;
}

- (NSImage *)pressedImage
{
	return self.alternateImage;
}

- (void)setEnabled:(BOOL)enabled
{
	super.enabled = enabled;
	[self updateActiveImage];
}

- (void)updateRollOverImage
{
	if (self.group.shouldDisplayRollOver && self.isEnabled) {
		self.image = self.rolloverImage;
	} else {
		[self updateImage];
	}
}

- (void)updateImage
{
	if (self.window.isKeyWindow) {
		[self updateActiveImage];
	} else {
		self.image = self.activeNotKeyWindowImage;
	}
}

- (void)updateActiveImage
{
	self.image = self.isEnabled ? self.activeImage : self.inactiveImage;
}

@end