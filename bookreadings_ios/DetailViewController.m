//
//  DetailViewController.m
//  bookreadings_ios
//
//  Created by Reath, Chris X. -ND on 3/18/15.
//  Copyright (c) 2015 Reath, Chris X. -ND. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>
#import "DetailViewController.h"
#import "AZCenterLabelButton.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize duration, progress, playPauseButton, slider, draggingProgressSlider, coverImage, widthConstraint;

static NSString* const CLOUD_FRONT_URL_AUDIO = @"https://d3e04w4j2r2rn6.cloudfront.net/";
static NSString* const CLOUD_FRONT_URL_IMAGE = @"https://d1onveq9178bu8.cloudfront.net";
static int const HEIGHT_OF_IMAGE = 200;

#pragma mark - Managing the detail item

- (void)setDetailItem:(Reading*)newReading {
    if (_reading != newReading) {
        _reading = newReading;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {

    if (self.reading) {
        
        // Update the user interface for the detail item.
        NSString * audioFileURLString = [NSString stringWithFormat:@"%@%@", CLOUD_FRONT_URL_AUDIO, self.reading.audioKey];
        self.audioPlayer = [[STKAudioPlayer alloc] init];
        [self.audioPlayer play:audioFileURLString];
        
        self.readingPlaying = TRUE;
       
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(setProgressAndDuration)
                                       userInfo:nil
                                        repeats:YES];
        
    }
}

- (IBAction)editingDidBegin:(id)sender {
    
    draggingProgressSlider = TRUE;
    
    self.progress.text = [self timeFormatted:self.slider.value];
    
    
}
- (IBAction)editingDidEnd:(id)sender {
    
    draggingProgressSlider = FALSE;
    
    float valueToSeekTo = self.slider.value;
    [self.audioPlayer seekToTime:valueToSeekTo];
    
}

-(void)setProgressAndDuration {
    
    if(!draggingProgressSlider) {
    
        //set the duraiton and progress
        self.duration.text = [self timeFormatted:(int)[self.audioPlayer duration]];
        self.progress.text = [self timeFormatted:(int)[self.audioPlayer progress]];
        
        self.slider.maximumValue = [self.audioPlayer duration];
        self.slider.value = [self.audioPlayer progress];
    }
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60);
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (IBAction)playPausePressed:(id)sender {
    
    if(self.readingPlaying) {
        [playPauseButton setImage:[UIImage imageNamed:@"playbutton.png"] forState:UIControlStateNormal];
        [self.audioPlayer pause];
        self.readingPlaying = FALSE;
    } else {
        [playPauseButton setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
        [self.audioPlayer resume];
        self.readingPlaying = TRUE;
    }
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];    // Call the super class implementation.
    // Usually calling super class implementation is done before self class implementation, but it's up to your application.
    
    [self.audioPlayer stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    UIImage *sliderThumb = [UIImage imageNamed:@"uislider-thumb.png"];
    [slider setThumbImage:sliderThumb forState:UIControlStateNormal];
    [slider setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    
    if(_reading) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat width = screenRect.size.width;
        NSString * screenWidth = [NSString stringWithFormat: @"%d",(int)width];
        CGFloat height = HEIGHT_OF_IMAGE;
        NSString * cellHeight = [NSString stringWithFormat: @"%d",(int)height];
       
        //modifying the width constraint on the fly
        //http://stackoverflow.com/questions/23655096/change-frame-programmatically-with-auto-layout
        //
        widthConstraint.constant = width;
        
        NSString * coverImageString = [NSString stringWithFormat:@"%@%@/convert?w=%@&h=%@&fit=crop", CLOUD_FRONT_URL_IMAGE, _reading.coverImageURL, screenWidth, cellHeight];

        //set the background image
        coverImage.contentMode = UIViewContentModeTopLeft;
        [coverImage sd_setImageWithURL:[NSURL URLWithString:coverImageString]
                          placeholderImage:nil];
        
        
        //gradient over UIImage
        CAGradientLayer *gradient = [CAGradientLayer layer];
        
        gradient.frame = CGRectMake(0, 0, self.coverImage.bounds.size.width, 7);
        gradient.colors = @[(id)[[UIColor colorWithWhite:0 alpha:0.2] CGColor],
                            (id)[[UIColor colorWithWhite:0 alpha:0.15] CGColor],
                            (id)[[UIColor colorWithWhite:0 alpha:0.1] CGColor],
                            (id)[[UIColor colorWithWhite:0 alpha:0.05] CGColor],
                            (id)[[UIColor clearColor] CGColor]];
        [self.coverImage.layer insertSublayer:gradient atIndex:0];
        
        [self populateCommentBubble];
        
    }
}

-(void)populateCommentBubble {
    
    //comment bubble and count
    CGRect rect = CGRectMake(0, 0, 30, 30);
    UIButton *button  = [[UIButton alloc] initWithFrame:rect];
    [button setImage:[UIImage imageNamed:@"SpeachBubble.png"] forState:UIControlStateNormal];
    button.titleLabel.textColor=[UIColor whiteColor];
    
    NSInteger commentCount = [self.reading commentCount];
    
    button.titleLabel.font = [UIFont systemFontOfSize:9];;
    
    if(commentCount >= 100) {
        button.titleLabel.font = [UIFont systemFontOfSize:6];
    }
   
    float offset = -25;
    if(commentCount >= 10) {
        offset = -30;
    } else if (commentCount >= 100){
        offset = -40;
    }
    
    button.imageEdgeInsets = UIEdgeInsetsMake(5,
                                            0.0f,
                                            0.0f,
                                            offset);
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0f,
                                            -5.0,
                                            0.0f,
                                            0.0f);
    
    
    [button setTitle:[@(commentCount) stringValue] forState:UIControlStateNormal];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem= rightBarButtonItem;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
