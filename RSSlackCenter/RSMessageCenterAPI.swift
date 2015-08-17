//
//  RSMessageCenterAPI.swift
//  RSSlackCenter
//
//  Created by Reinder de Vries on 12-08-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Alamofire

class RSMessageCenterAPI: NSObject
{
    /// Singleton static instance of `RSMessageCenterAPI`
    static let sharedInstance = RSMessageCenterAPI();
    
    /// ID of the Slack channel the chat happens in
    var channelID:String?;
    
    /// Counter of subsequent Slack chat messages
    var messageID:Int = 0;
    
    /// ID of the Slack bot, called "i-am-user" by default
    var botID:String?;
    
    /// Dictionary of Slack users available, retrieved in the `rtm_start` method
    var users:[String: [String: AnyObject]] = [String: [String: AnyObject]]();
    
    /// Image data of the Slack users
    var users_avatar:[String: NSData] = [String:NSData]();
    
    /**
        Starts the process of connecting to Slack RTM, downloading avatars, checking the channel etc. 
        Initial starting point, readies the message center.
    */
    func configureChat()
    {
        RSSlackAPI.sharedInstance.rtm_start {
            (url:String) -> Void in
            
            RSSocketAPI.sharedInstance.connect(NSURL(string: url)!);
            
            self.getAvatars();
            
            self.setupChannel();
            
            return;
        }
    }
    
    /**
        Sets up the Slack channel. First, the admin user attempts to join a new channel. The new channel ID
        is stored in the user defaults. When it's present, or when a newly created channel has been joined, the 
        bot user is invited over to the channel. When the bot is already a member of the channel, the invite is
        still attempted, but this has no adverse effect (except for being not optimized).
    
        The new channel name is random, a string of 4 alphanumeric characters and a random name from `Slack.misc.usernames`.
    */
    func setupChannel()
    {
        if let channelID = NSUserDefaults.standardUserDefaults().stringForKey(MessageCenter.prefs.channelID)
        {
            self.channelID = channelID;
            
            self.inviteBotToChannel();
        }
        else
        {
            let channel_name = self.getRandomChannelName();
            
            RSSlackAPI.sharedInstance.channels_join(channel_name) {
                (channelID:String) -> Void in
                
                NSUserDefaults.standardUserDefaults().setValue(channelID, forKey: MessageCenter.prefs.channelID);
                
                self.channelID = channelID;
                
                self.inviteBotToChannel();
            }
        }
    }
    
    /**
        Invites the bot user to a channel. The bot user is identified by `self.botID`, which a result of the 
        `RSSlackAPI rtm_start` method. The channel ID is a result of the `channels_join` method in `setupChannel`.

        The result of the async web call isn't used.
    */
    func inviteBotToChannel()
    {
        if(self.channelID == nil || self.botID == nil)
        {
            return;
        }
        
        RSSlackAPI.sharedInstance.channels_invite(self.channelID!, userID: self.botID!, completion: nil);
        
    }
    
    /**
        Sends a message to the Slack channel, if connected.

        :param: text The simple text message to send.
    */
    func sendMessage(text:String)
    {
        if RSSocketAPI.sharedInstance.isConnected && channelID != nil
        {
            messageID++;
            
            RSSocketAPI.sharedInstance.sendMessage(messageID, type: "message", channelID: channelID!, text: text);
        }
    }
    
    /**
        Gets the avatar image data from S3 and stores it in property `users_avatar`, identified by the user `id`.
        Iterates over `self.users`, a result of the `rtm_start` method.
    */
    func getAvatars()
    {
        for (id, user) in self.users
        {
            if let url = user[Slack.param.image] as? String
            {
                Alamofire.request(.GET, url, parameters: nil).response {
                    request, response, data, error in
                    
                    if error != nil
                    {
                        println(error!.localizedDescription);
                        return;
                    }
                    
                    if data != nil
                    {
                        self.users_avatar[id] = data!;
                    }
                }
            }
        }        
    }
    
    /**
        Generate a random channel name. Consists of 4 random alphanumeric characters, a dash, and a 
        random name from `Slack.misc.usernames`. These *usernames* identify single Message Center users
        in Slack.

        :returns: A random name string.
    */
    func getRandomChannelName() -> String
    {
        let prefix = self.randomStringWithLength(4);
        let username = Slack.misc.usernames[Int(arc4random()) % Int(count(Slack.misc.usernames))];
        
        return "\(prefix)-\(username)";
    }
    
    
    
    //
    
    /**
        Generate a random string with `length` length.

        :param: length The length of the random string.
        :returns: A random string.
    
        :author: MattDiPasquale https://stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa/30949359#30949359
    */
    func randomStringWithLength(length: Int) -> String
    {
        let alphabet = "1234567890abcdefghijklmnopqrstuvwxyz";
        let upperBound = UInt32(count(alphabet));
        
        return String((0..<length).map { _ -> Character in
            return alphabet[advance(alphabet.startIndex, Int(arc4random_uniform(upperBound)))]
        })
    }
    
    /**
        Utility method that turns a hex string (ex. #00ff00) into a `UIColor` instance.

        :author: arshad https://gist.github.com/arshad/de147c42d7b3063ef7bc
    */
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        if (count(cString) != 6) {
            return UIColor.grayColor()
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
}
