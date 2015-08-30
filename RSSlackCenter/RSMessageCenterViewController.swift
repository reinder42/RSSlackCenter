//
//  RSMessageCenterViewController.swift
//  RSSlackCenter
//
//  Created by Reinder de Vries on 10-08-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class RSMessageCenterViewController: JSQMessagesViewController
{
    var messages:[JSQMessage] = [JSQMessage]();
    var showTypingIndicatorTimer:NSTimer?;
    
    // MARK: View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        self.senderId = "1234";
        self.senderDisplayName = "me";
        
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        
        self.inputToolbar.contentView.leftBarButtonItem = nil;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onNewMessageReceived:"), name: MessageCenter.notification.newMessage, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onUserTypingReceived:"), name: MessageCenter.notification.userTyping, object: nil);
        
        RSMessageCenterAPI.sharedInstance.configureChat();
    }
    
    // MARK: User typing notifs and timer
    
    /**
        Received a notification that a Slack user is typing. The method then invalidates and restarts the timer,
        effectively mimicking a countdown timer. When multiple "user is typing" notifications are received, the
        notifications are debounced and show a continuous "user is typing" blurb to the app user.

        :param notification The received notification
    */
    func onUserTypingReceived(notification:NSNotification)
    {
        self.showTypingIndicator = true;
        
        showTypingIndicatorTimer?.invalidate();
        showTypingIndicatorTimer = nil;
        
        showTypingIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("onTypingIndicatorTimerFire"), userInfo: nil, repeats: false);
    }
    
    /**
        Method that fires when the `showTypingIndicatorTimer` runs out. Hides the "user is typing" indicator.
    */
    func onTypingIndicatorTimerFire()
    {
        self.showTypingIndicator = false;
        
        showTypingIndicatorTimer?.invalidate();
        showTypingIndicatorTimer = nil;
    }
    
    // MARK: Sending and receiving messages
    
    /**
        Override method that's called when the user presses the send button. Adds a new `JSQMessage` to the message list,
        then sends the message text to the Slack channel.
    */
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!)
    {
        let message = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: text);
        messages += [message];
        
        RSMessageCenterAPI.sharedInstance.sendMessage(text);
        
        self.finishSendingMessageAnimated(true);
    }
    
    /**
        Received a notification that a new message is received. Message details are stored in `userInfo`. The method
        adds a new `JSQMessage` to the message list, hides the typing indicator, then reloads the message view.
    
        :param: notification The notification
    */
    func onNewMessageReceived(notification:NSNotification)
    {
        if  let info = notification.userInfo as? [String: String],
            let text = info[Slack.param.text],
            let user = info[Slack.param.user]
        {
            let message = JSQMessage(senderId: user, displayName: user, text: text);
            messages += [message];
            
            self.showTypingIndicator = false;
            
            self.collectionView.reloadData();
        }
    }
    
    // MARK: JSQ Collection view
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return count(messages);
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData!
    {
        return self.messages[indexPath.item];
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource!
    {
        let message = self.messages[indexPath.item];
        let factory = JSQMessagesBubbleImageFactory();
        
        if(message.senderId == self.senderId)
        {
            return factory.outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor());
        }
        
        if  let user = RSMessageCenterAPI.sharedInstance.users[message.senderId],
            let color = user[Slack.param.color] as? String
        {
            // This is the Slack user color
            return factory.incomingMessagesBubbleImageWithColor(RSMessageCenterAPI.sharedInstance.colorWithHexString(color));
        }
        
        return factory.outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor());
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath);
        
        // This doesn't really do anything, but it's a good point for customization
        let message = self.messages[indexPath.item];
        
        return cell;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource!
    {
        let message = self.messages[indexPath.item];
        
        if let data = RSMessageCenterAPI.sharedInstance.users_avatar[message.senderId]
        {
            return JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: data)!, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault));
        }
        
        return nil;
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning();
    }
}
