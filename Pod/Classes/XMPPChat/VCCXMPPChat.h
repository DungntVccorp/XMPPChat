//
//  GzChat.h
//  GzoneLib
//
//  Created by Nguyen Dung on 26/02/2015.
//  Copyright (c) Năm 2015 dungnt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XMPPFramework.h"
#import "XMPPRoster.h"
#import "XMPPReconnect.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPvCardTempModule.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import <CoreData/CoreData.h>
#import "TURNSocket.h"
#import "XMPPOutgoingFileTransfer.h"
#import "XMPPIncomingFileTransfer.h"
#import "XMPPFileTransfer.h"
#import "XMPPNamespaces.h"
#import "XMPPFileTransfer.h"

@protocol XMPP_RegisterDelegate <NSObject>
@optional
-(void)RegisterDidSuccess;
-(void)RegisterDidFalse:(NSString *)message;
@end
@protocol XMPP_LoginDelegate <NSObject>
@optional
-(void)LoginDidSuccess;
-(void)LoginDidFalse:(NSString *)message;

@end



#define STATUS_REGISTER @"r_sr"
#define GET_FRIEND_LIST @"g_fl"


@interface VCCXMPPChat : NSObject <XMPPRosterDelegate,XMPPStreamDelegate,XMPPIncomingFileTransferDelegate,XMPPOutgoingFileTransferDelegate>
{
    XMPPStream *xmppStream;
    XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
    XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
    XMPPvCardTempModule *xmppvCardTempModule;
    XMPPvCardAvatarModule *xmppvCardAvatarModule;
    XMPPCapabilities *xmppCapabilities;
    XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    XMPPIncomingFileTransfer *xmppIncomingFileTransfer;
    XMPPOutgoingFileTransfer *fileTransfer;
    NSString *currentUserName;
    NSString *currentPassword;
    NSString *currentDisplayName;
    NSString *currentEmail;
    NSString *currentHostName;
    UInt16 currenthostport;
    // status
    BOOL WAIT_STATUS_REGISTER;
    BOOL WAIT_STATUS_LOGIN;
}
@property(nonatomic,retain)XMPPStream *xmppStream;
@property(nonatomic,retain)XMPPvCardAvatarModule *xmppvCardAvatarModule;

@property (copy) void (^sendFileCallBack)(BOOL status,NSError *error);
@property (copy) void (^incomingFileCallBack)(BOOL status,NSString *filepath,NSError *error);
@property (copy) void (^didInComingMessage)(NSString *message,id userSend);
@property (copy) void (^didAddBuddy)();
@property (copy) void (^didSubCribeBuddy)(XMPPJID *jid);
//delegate

@property(nonatomic,retain)id<XMPP_RegisterDelegate>registerDelegate;
@property(nonatomic,retain)id<XMPP_LoginDelegate>loginDelegate;






+(instancetype)shareIntance;

- (void)configStreamWithHostName:(NSString *)hostName hostPort:(UInt16)hostport;


// Register
- (void)registerWithHostName:(NSString *)hostName hostPort:(UInt16)hostport userName:(NSString *)userName password:(NSString *)password displayName:(NSString *)displayname email:(NSString *)emailAddress delegate:(id/*registerDelegate*/)delegate;
//Login
-(void)loginWithUserName:(NSString *)username password:(NSString *)password delegate:(id)delegate;
-(void)goOnline;
-(void)goOffline;
// core data
- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
// get friends
- (void)fetchFriends;
// send message
-(void)sendMessage:(NSString *)messageStr destination:(XMPPJID *)destination;
-(void)sendData:(NSData *)data DataFileName:(NSString *)fileName Message:(NSString *)messageStr destination:(XMPPJID *)destination;
// add friend
-(void)addBuddyWith:(XMPPJID *)jidBuddy withNickname:(NSString *)nickName;
-(void)acceptBuddyWith:(XMPPJID *)jid;
-(void)rejectBuddyWith:(XMPPJID *)jid;
-(void)removeBuddy:(XMPPJID *)jid;
// get message offline
-(void)getMessageOffline;


+(instancetype)shareIntanceWithHostName:(NSString *)hostName hostPort:(UInt16)hostport;

-(void)loginWithUserName:(NSString *)username password:(NSString *)password;


@end







