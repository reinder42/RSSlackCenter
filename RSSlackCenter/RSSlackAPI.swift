//
//  RSSlackAPI.swift
//  RSSlackCenter
//
//  Created by Reinder de Vries on 10-08-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class RSSlackAPI: NSObject
{
    /// Singleton instance of `RSSlackAPI`
    static let sharedInstance = RSSlackAPI();
    
    /**
        Send "rtm_start" HTTPS API request to Slack. Returns info about users, channels, and the websocket RTM URL.
        This method also searches the user data for the ID of the user bot `Slack.misc.bot_name`, and stores all relevant user
        data (ID, profile, color and image URL). Finally, it calls the `completion` closure when the request is finished. It's recommended
        you connect to the websocket, because it closes in 30 seconds after "rtm_start".
    
        :param: completion Closure that's called upon completion of this method.
    */
    func rtm_start(completion: (String) -> Void)
    {
        Alamofire.request(.GET, Slack.URL.rtm.start, parameters: [Slack.param.token: Slack.token.bot]).responseJSON {
            request, response, data, error in
            
            if error != nil
            {
                println(error!.localizedDescription);
                return;
            }
            
            let json = JSON(data!);
            
            println(json);
            
            if let users = json[Slack.param.users].array
            {
                for user in users
                {
                    // Figure out user ID of bot
                    if user[Slack.param.name].string != nil && user[Slack.param.name].stringValue == Slack.misc.bot_name
                    {
                        RSMessageCenterAPI.sharedInstance.botID = user[Slack.param.id].string;
                    }
                    
                    // Store user data in RSMessageCenterAPI for later reference
                    var user_data = [String: AnyObject]();
                    
                    if  let id = user[Slack.param.id].string,
                        let profile = user[Slack.param.profile].dictionary,
                        let color = user[Slack.param.color].string,
                        let image = profile[Slack.param.image_32]?.string
                    {
                        user_data[Slack.param.color] = color;
                        user_data[Slack.param.image] = image;
                                                
                        RSMessageCenterAPI.sharedInstance.users[id] = user_data;
                    }
                }
            }
            
            // Get websocket URL and call completion closure
            if let url = json[Slack.param.url].string
            {
                completion(url);
            }
            
        }
    }
    
    /**
        Send "channels_join" HTTPS API request to Slack. Uses the admin token (i.e. the admin user) to
        join a new channel with `channel_name`. To Slack, joining a channel creates a channel when it doesn't exist yet.
        The `completion` closure is executed when the request finishes, if the returned data is OK.

        :param: channel_name String with the name of the channel.
        :param: completion Closure with `channelID` parameter.
    */
    func channels_join(channel_name:String, completion: (channelID: String) -> Void)
    {
        Alamofire.request(.GET, Slack.URL.channels.join, parameters: [Slack.param.token: Slack.token.admin, Slack.param.name: channel_name]).responseJSON {
            request, response, data, error in
            
            if error != nil
            {
                println(error!.localizedDescription);
                return;
            }
            
            let json = JSON(data!);
            
            if  let channel = json[Slack.param.channel].dictionary,
                let channelID = channel[Slack.param.id]?.string
            {
                completion(channelID: channelID);
            }
        }
    }
    
    /**
        Send "channels_invite" HTTPS API request to Slack. Used to invite a user with `userID` to channel with `channelID`. Calls a closure upon completion.
        In the example project, this is used to invite the bot user to the new message center channel. The admin user is already invited, because it created/joined the channel.
    
        :param: channelID The channel to invite to.
        :param: userID The user ID of the user to invite to the channel.
        :param: completion Optional closure to be called when the request finishes.
    */
    func channels_invite(channelID:String, userID:String, completion: (() -> Void)?)
    {
        Alamofire.request(.GET, Slack.URL.channels.invite, parameters: [Slack.param.token: Slack.token.admin, Slack.param.channel: channelID, Slack.param.user: userID]).responseJSON {
            request, response, data, error in
            
            if error != nil
            {
                println(error!.localizedDescription);
                return;
            }
            
            let json = JSON(data!);
            
            println(json);
            
            if(completion != nil)
            {
                completion!();
            }
        }
    }
    
    
}
