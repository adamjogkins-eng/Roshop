#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Global variables for tracking
NSDate *joinTime;
NSTimer *playtimeTimer;
NSInteger segmentsAwarded = 0;

// Helper to update coins and notify your webhook/UI
void updateBalance(NSInteger amount, NSString *reason) {
    NSInteger current = [[NSUserDefaults standardUserDefaults] integerForKey:@"RBX_Coins"];
    [[NSUserDefaults standardUserDefaults] setInteger:(current + amount) forKey:@"RBX_Coins"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[Shop] +%ld Coins for: %@", (long)amount, reason);
}

// 1. Playtime Logic: 40 coins per 15 mins after first 20 mins
void startPlaytimeTracker() {
    joinTime = [NSDate date];
    playtimeTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:joinTime];
        double minutes = duration / 60.0;
        
        // After 20 mins, check for every 15-min segment
        if (minutes >= 20) {
            NSInteger currentSegments = (NSInteger)((minutes - 20) / 15);
            if (currentSegments > segmentsAwarded) {
                updateBalance(40, @"Playtime Reward");
                segmentsAwarded = currentSegments;
            }
        }
    }];
}

// 2. Purchase Logic: Only over 50 Robux
// Note: You must hook the Roblox Purchase function (ProcessReceipt) to get 'amount'
void handlePurchase(int robuxSpent) {
    if (robuxSpent >= 50) {
        updateBalance(120, @"Significant Purchase");
    } else {
        NSLog(@"[Shop] Purchase under 50 Robux. No reward.");
    }
}

// 3. Friend Join Logic
void checkFriendJoin() {
    NSString *launchParams = [[NSProcessInfo processInfo] arguments].description;
    if ([launchParams containsString:@"followUserId"]) {
        updateBalance(75, @"Joined Friend");
    } else {
        updateBalance(50, @"Joined Experience");
    }
}

__attribute__((constructor))
static void init() {
    // Wait for game to stabilize
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        checkFriendJoin();
        startPlaytimeTracker();
    });
}
