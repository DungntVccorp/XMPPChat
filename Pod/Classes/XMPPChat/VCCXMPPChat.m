//
//  GzChat.m
//  GzoneLib
//
//  Created by Nguyen Dung on 26/02/2015.
//  Copyright (c) Năm 2015 dungnt. All rights reserved.
//

#import "VCCXMPPChat.h"
@import UIKit;

@implementation VCCXMPPChat
@synthesize xmppStream;
@synthesize xmppvCardAvatarModule;
- (void)setupStream{
    currenthostport = 0;
    xmppStream = [[XMPPStream alloc] init];
    xmppReconnect = [[XMPPReconnect alloc] init];
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    xmppRoster.autoFetchRoster = YES;
    xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    [xmppReconnect         activate:xmppStream];
    [xmppRoster            activate:xmppStream];
    [xmppvCardTempModule   activate:xmppStream];
    [xmppvCardAvatarModule activate:xmppStream];
    [xmppCapabilities      activate:xmppStream];
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    
}
- (void)configStreamWithHostName:(NSString *)hostName hostPort:(UInt16)hostport{
    currentHostName = hostName;
    currenthostport = hostport;
    [xmppStream setHostName:hostName];
    [xmppStream setHostPort:hostport];
}
+(instancetype)shareIntance{
    static VCCXMPPChat *share = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        share = [[VCCXMPPChat alloc]init];
        [share setupStream];
    });
    return share;
}

#pragma mark SOCKET

- (BOOL)connect{
    if (![xmppStream isDisconnected]) {
        return YES;
    }
    if (currentUserName == nil || currentPassword == nil) {
        return NO;
    }
    [xmppStream setMyJID:[XMPPJID jidWithString:currentUserName]];
    NSError *error = nil;
    if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        
        return NO;
    }
    return YES;
}
- (void)disconnect
{
    [self goOffline];
    [xmppStream disconnect];
}



- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
}
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{

}
- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
}
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    if(WAIT_STATUS_REGISTER){
        WAIT_STATUS_REGISTER = NO;
        [self RegisterWithUserName:currentUserName password:currentPassword displayName:currentDisplayName email:currentEmail];
    }
    else if(WAIT_STATUS_LOGIN){
        WAIT_STATUS_LOGIN = NO;
        [self.xmppStream authenticateWithPassword:currentPassword error:nil];
    }
}
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    WAIT_STATUS_LOGIN = NO;
    if([_loginDelegate performSelector:@selector(LoginDidSuccess)]){
        [_loginDelegate LoginDidSuccess];
    }
    [self goOnline];
}
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    WAIT_STATUS_LOGIN = NO;
   
    if ([_loginDelegate respondsToSelector:@selector(LoginDidFalse:)] ){
        [_loginDelegate LoginDidFalse:error.description];
    }
     [self disconnect];
}
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"%@",iq.description);
    if([iq.elementID isEqualToString:STATUS_REGISTER]){
        if(iq.isErrorIQ){
            // register false
            if ([_registerDelegate respondsToSelector:@selector(RegisterDidFalse:)] ){
                [_registerDelegate RegisterDidFalse:@"Username is taken"];
            }
            
        }
        else if(iq.isResultIQ){
            if([_registerDelegate respondsToSelector:@selector(RegisterDidSuccess)]){
                [_registerDelegate RegisterDidSuccess];
            }
            
        }
        return YES;
        
    }
    
    if([iq.elementID isEqualToString:GET_FRIEND_LIST]){
        return YES;
    }
    
    if([self isSofwareVersion:iq]){
        [self SendVersion:iq];
        return YES;
    }

    /*
    <iq xmlns="jabber:client" type="get" to="dung.nt@dungnts.local/gzchat" id="9451304A-3EE7-47EA-8C0A-347D2033ECEB" from="khoa.ln@dungnts.local/gzchat"><query xmlns="http://jabber.org/protocol/disco#info"/></iq>
     
     SEND 
     
     <iq type="result" to="khoa.ln@dungnts.local/gzchat" id="0E32B47F-0257-47DA-9F5F-712E4975984C" from="dung.nt@dungnts.local/gzchat"><query xmlns="http://jabber.org/protocol/disco#info"><identity category="client" type="ios-osx"/><feature var="http://jabber.org/protocol/si"/><feature var="http://jabber.org/protocol/si/profile/file-transfer"/><feature var="http://jabber.org/protocol/bytestreams"/><feature var="http://jabber.org/protocol/ibb"/></query></iq>
     
     
     SEND 
     <iq type="result" to="khoa.ln@dungnts.local/gzchat" id="53B569B1-AFEE-4085-9C3E-BF0DC09A5B38" from="dung.nt@dungnts.local/gzchat"><query xmlns="http://jabber.org/protocol/disco#info"><identity category="client" type="ios-osx"/><feature var="http://jabber.org/protocol/si"/><feature var="http://jabber.org/protocol/si/profile/file-transfer"/><feature var="http://jabber.org/protocol/bytestreams"/><feature var="http://jabber.org/protocol/ibb"/></query></iq>
     
     
     
     <iq xmlns="jabber:client" type="get" to="dung.nt@dungnts.local/gzchat" id="B605AAFC-44D6-40B7-BDB3-5A742B71D26Dsdfsdfsdfsdfsdfffffffdasd" from="khoa.ln@dungnts.local/gzchat"><query xmlns="http://jabber.org/protocol/disco#info"/></iq>
     
     
     <iq xmlns="jabber:client" type="set" to="dung.nt@dungnts.local/gzchat" id="4F98C18F-4F8F-4B73-A1B8-37492653EB9C" from="khoa.ln@dungnts.local/gzchat"><si xmlns="http://jabber.org/protocol/si" id="E156199D-2C5F-4982-8097-39BC09D00F56" profile="http://jabber.org/protocol/si/profile/file-transfer"><file xmlns="http://jabber.org/protocol/si/profile/file-transfer" name="test.jpeg" size="753"><desc>abc</desc></file><feature xmlns="http://jabber.org/protocol/feature-neg"><x xmlns="jabber:x:data" type="form"><field var="stream-method" type="list-single"><option><value>http://jabber.org/protocol/bytestreams</value></option><option><value>http://jabber.org/protocol/ibb</value></option></field></x></feature></si></iq>
     
     <iq xmlns="jabber:client" type="set" to="dung.nt@dungnts.local/gzchat" id="7FB9B62E-3486-4D0B-B5F9-DC25EB4C38B4" from="khoa.ln@dungnts.local/gzchat"><query xmlns="http://jabber.org/protocol/bytestreams" sid="E156199D-2C5F-4982-8097-39BC09D00F56"><streamhost jid="khoa.ln@dungnts.local/gzchat" host="192.168.1.14" port="6210"/><streamhost jid="proxy.dungnts.local" host="192.168.1.9" port="1234"/></query></iq>
     
     */
    if (xmppIncomingFileTransfer._transferState == XMPPIFTStateNone && [self isDiscoInfoIQ:iq]) {
        [self sendIdentity:iq];
        xmppIncomingFileTransfer._transferState = XMPPIFTStateWaitingForSIOffer;
        return YES;
    }
    
    if ((xmppIncomingFileTransfer._transferState == XMPPIFTStateNone || xmppIncomingFileTransfer._transferState == XMPPIFTStateWaitingForSIOffer)
        && [self isSIOfferIQ:iq]) {
        // Alert the delegate that we've received a stream initiation offer
        [self didReceiveSIOffer:iq];
        
        if (xmppIncomingFileTransfer.autoAcceptFileTransfers) {
            [xmppIncomingFileTransfer sendSIOfferAcceptance:iq];
        }
        
        return YES;
    }
    
    if (xmppIncomingFileTransfer._transferState == XMPPIFTStateWaitingForStreamhosts && [xmppIncomingFileTransfer isStreamhostsListIQ:iq]) {
        [xmppIncomingFileTransfer attemptStreamhostsConnection:iq];
        return YES;
    }
    
    if (xmppIncomingFileTransfer._transferState == XMPPIFTStateWaitingForIBBOpen && [xmppIncomingFileTransfer isIBBOpenRequestIQ:iq]) {
        [xmppIncomingFileTransfer sendIBBAcceptance:iq];
        xmppIncomingFileTransfer._transferState = XMPPIFTStateWaitingForIBBData;
        
        // Handle the scenario that the transfer is cancelled.
        [xmppIncomingFileTransfer resetIBBTimer:20];
        return YES;
    }
    
    if (xmppIncomingFileTransfer._transferState == XMPPIFTStateWaitingForIBBData && [xmppIncomingFileTransfer isIBBDataIQ:iq]) {
        [xmppIncomingFileTransfer processReceivedIBBDataIQ:iq];
        return YES;
    }
    
    
    
    return NO;
}



- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isChatMessageWithBody])
    {
        XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
                                                                 xmppStream:xmppStream
                                                       managedObjectContext:[self managedObjectContext_roster]];
        if([user.primaryResource jidStr]){
            NSString *body = [[message elementForName:@"body"] stringValue];
            
            NSString *displayName = [user displayName];
            
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
            {
                
                if(self.didInComingMessage){
                    self.didInComingMessage(body,user);
                }
            }
            else
            {
                // We are not active, so use a local notification instead
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertAction = @"Ok";
                localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
                
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    
    if([presence.type isEqualToString:@"subscribe"]){
        NSLog(@"subscribe - %@",presence.fromStr);
        if(self.didSubCribeBuddy){
            self.didSubCribeBuddy([XMPPJID jidWithString:presence.fromStr ]);
        }
    }
    

}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    WAIT_STATUS_REGISTER = NO;
    WAIT_STATUS_LOGIN = NO;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
    return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
    return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}
#pragma mark XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence{
}
- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender{
}
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
}

#pragma mark REGISTER USER
- (void)registerWithHostName:(NSString *)hostName hostPort:(UInt16)hostport userName:(NSString *)userName password:(NSString *)password displayName:(NSString *)displayname email:(NSString *)emailAddress delegate:(id/*registerDelegate*/)delegate{
    if(hostName.length == 0 || hostName == 0 || userName.length == 0 || password.length == 0){
        NSLog(@"hostName or hostport or userName or password Không được để trống");
        return;
    }
    if(delegate){
        [[VCCXMPPChat shareIntance] setRegisterDelegate:delegate];
    }
    [self configStreamWithHostName:hostName hostPort:hostport];
    if(xmppStream.isConnected){
        // đã mở kết nối gửi luôn message register
        [self RegisterWithUserName:userName password:password displayName:displayname email:emailAddress];
    }
    else{
        WAIT_STATUS_REGISTER = YES;
        currentDisplayName = displayname;
        currentEmail = emailAddress;
        currentUserName = userName;
        currentPassword = password;
        // cm chưa mở kết nối mở kết nối rồi mở message
        
        [self connect];
    }
}
-(void)RegisterWithUserName:(NSString *)userName password:(NSString *)password displayName:(NSString *)displayname email:(NSString *)emailAddress
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    [query addChild:[NSXMLElement elementWithName:@"username" stringValue:userName]];
    [query addChild:[NSXMLElement elementWithName:@"password" stringValue:password]];
    [query addChild:[NSXMLElement elementWithName:@"name" stringValue:displayname]];
    [query addChild:[NSXMLElement elementWithName:@"email" stringValue:emailAddress]];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    [iq addAttributeWithName:@"id" stringValue:STATUS_REGISTER];
    [iq addChild:query];
    [xmppStream sendElement:iq];
}


#pragma mark LOGIN

-(void)loginWithUserName:(NSString *)username password:(NSString *)password delegate:(id)delegate{
    
    if(currentHostName == nil || currenthostport == 0){
        NSLog(@"config host name va host post truoc -- configStreamWithHostName");
        return;
    }
    if(delegate){
        [self setLoginDelegate:delegate];
    }
    currentUserName = username;
    currentPassword = password;
    XMPPJID *jid = [XMPPJID jidWithString:username];
    self.xmppStream.myJID = jid;
    if(!xmppStream.isConnected){
        // start connect
        WAIT_STATUS_LOGIN = YES;
        [self connect];
    }
    else{
        // authen
        [[self xmppStream] authenticateWithPassword:password error:nil];
    }
    
}
-(void)goOnline{
    if(!self.xmppStream.isConnected){
        return;
    }
    XMPPPresence *presence = [XMPPPresence presence];
    NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
    [presence addChild:priority];
    [[self xmppStream] sendElement:presence];
    
    xmppIncomingFileTransfer = [[XMPPIncomingFileTransfer alloc]init];
    [xmppIncomingFileTransfer activate:xmppStream];
    xmppIncomingFileTransfer._transferState = XMPPIFTStateNone;
    [xmppIncomingFileTransfer setDelegate:self];
}


-(void)goOffline{
    if(!self.xmppStream.isConnected){
        return;
    }
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
    [xmppIncomingFileTransfer removeDelegate:self];
    [xmppIncomingFileTransfer deactivate];
}

#pragma mark FetchFriends

- (void)fetchFriends
{
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
    [[self xmppStream] sendElement:presence];
}
-(void)sendMessage:(NSString *)messageStr destination:(XMPPJID *)destination{
    if([messageStr length] > 0)
    {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:destination.full];
        [message addChild:body];
        [xmppStream sendElement:message];
    }
}
-(void)sendData:(NSData *)data DataFileName:(NSString *)fileName Message:(NSString *)messageStr destination:(XMPPJID *)destination{
    
    fileTransfer = [[XMPPOutgoingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    [fileTransfer activate:xmppStream];
    [fileTransfer addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err;
    if (![fileTransfer sendData:data
                           named:fileName
                     toRecipient:destination
                     description:messageStr
                           error:&err]) {
    }
}
#pragma mark - XMPPOutgoingFileTransferDelegate Methods

- (void)xmppOutgoingFileTransfer:(XMPPOutgoingFileTransfer *)sender
                didFailWithError:(NSError *)error
{
    [fileTransfer removeDelegate:self];
    [fileTransfer deactivate];
    fileTransfer = nil;
    if (self.sendFileCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sendFileCallBack(FALSE,error);
        });
    }

}

- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender
{
    [fileTransfer removeDelegate:self];
    [fileTransfer deactivate];
    fileTransfer = nil;
    if (self.sendFileCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sendFileCallBack(YES,nil);
        });
        
    }
    
}




#pragma mark - XMPPIncomingFileTransferDelegate Methods

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
                didFailWithError:(NSError *)error
{
    if (self.incomingFileCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
        self.incomingFileCallBack(FALSE,nil,error);
        });
    }
}

- (void)didReceiveSIOffer:(XMPPIQ *)offer
{
    [xmppIncomingFileTransfer acceptSIOffer:offer];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
              didSucceedWithData:(NSData *)data
                           named:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *fullPath = [[paths lastObject] stringByAppendingPathComponent:name];
    [data writeToFile:fullPath options:0 error:nil];
    if (self.incomingFileCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
        self.incomingFileCallBack(YES,fullPath,nil);
        });
    }
}

- (BOOL)isDiscoInfoIQ:(XMPPIQ *)iq
{
    if (!iq) return NO;
    NSXMLElement *query = iq.childElement;
    return query != nil && [query.xmlns isEqualToString:XMPPDiscoInfoNamespace];
}
- (BOOL)isSIOfferIQ:(XMPPIQ *)iq
{
    if (!iq) return NO;
    if (![iq.type isEqualToString:@"set"]) return NO;
    
    NSXMLElement *si = iq.childElement;
    if (!si || ![si.xmlns isEqualToString:XMPPSINamespace]) return NO;
    
    NSXMLElement *file = (DDXMLElement *) [si childAtIndex:0];
    if (!file || ![file.xmlns isEqualToString:XMPPSIProfileFileTransferNamespace]) return NO;
    
    NSXMLElement *feature = (DDXMLElement *) [si childAtIndex:1];
    return !(!feature || ![feature.xmlns isEqualToString:XMPPFeatureNegNamespace]);
    
    // Maybe there should be further verification, but I think this should be
    // plenty...
}
- (void)sendIdentity:(XMPPIQ *)request
{
    XMPPIQ *iq = [XMPPIQ iqWithType:@"result"
                                 to:request.from
                          elementID:request.elementID];
    [iq addAttributeWithName:@"from" stringValue:xmppStream.myJID.full];
    
    NSXMLElement
    *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPDiscoInfoNamespace];
    
    NSXMLElement *identity = [NSXMLElement elementWithName:@"identity"];
    [identity addAttributeWithName:@"category" stringValue:@"client"];
    [identity addAttributeWithName:@"type" stringValue:@"ios-osx"];
    [query addChild:identity];
    
    NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
    [feature addAttributeWithName:@"var" stringValue:XMPPSINamespace];
    [query addChild:feature];
    
    NSXMLElement *feature1 = [NSXMLElement elementWithName:@"feature"];
    [feature1 addAttributeWithName:@"var" stringValue:XMPPSIProfileFileTransferNamespace];
    [query addChild:feature1];
    
    if (!xmppIncomingFileTransfer.disableSOCKS5) {
        NSXMLElement *feature2 = [NSXMLElement elementWithName:@"feature"];
        [feature2 addAttributeWithName:@"var" stringValue:XMPPBytestreamsNamespace];
        [query addChild:feature2];
    }
    
    if (!xmppIncomingFileTransfer.disableIBB) {
        NSXMLElement *feature3 = [NSXMLElement elementWithName:@"feature"];
        [feature3 addAttributeWithName:@"var" stringValue:XMPPIBBNamespace];
        [query addChild:feature3];
    }
    
    [iq addChild:query];
    [xmppStream sendElement:iq];
}


#pragma mark ADD Buddy

-(void)addBuddyWith:(XMPPJID *)jidBuddy withNickname:(NSString *)nickName{
    [xmppRoster addUser:jidBuddy withNickname:nickName];
    if(self.didAddBuddy){
        self.didAddBuddy();
    }
}
-(void)acceptBuddyWith:(XMPPJID *)jid{
    [xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
}
-(void)rejectBuddyWith:(XMPPJID *)jid{
    [xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
}
-(void)removeBuddy:(XMPPJID *)jid{
    [xmppRoster removeUser:jid];
}

#pragma mark Return Sofware Version

-(BOOL)isSofwareVersion:(XMPPIQ *)iq{
    if (!iq) return NO;
    if (![iq.type isEqualToString:@"get"]) return NO;
    NSXMLElement *queryElement = [iq elementForName: @"query" xmlns: @"jabber:iq:version"];
    if(!queryElement){
        return NO;
    }
    return YES;
}
-(void)SendVersion:(XMPPIQ *)iq{
    
    XMPPIQ *ver = [XMPPIQ iqWithType:@"result" to:iq.from elementID:iq.elementID];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:version"];
    [query addAttributeWithName:@"name" stringValue:@"VCCChat"];
    [query addAttributeWithName:@"version" stringValue:@"Beta"];
    
    [query addAttributeWithName:@"os" stringValue:[[[UIDevice currentDevice].systemName stringByAppendingString:@"-"] stringByAppendingString:[UIDevice currentDevice].systemVersion]];
    [ver addChild:query];
    [xmppStream sendElement:ver];
}

#pragma mark GetMessage Offline'

-(void)getMessageOffline{

}



// init

+(instancetype)shareIntanceWithHostName:(NSString *)hostName hostPort:(UInt16)hostport{
    static VCCXMPPChat *share = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        share = [[VCCXMPPChat alloc]init];
        [share setupStream];
        [share configStreamWithHostName:hostName hostPort:hostport];
    });
    return share;
}



@end
