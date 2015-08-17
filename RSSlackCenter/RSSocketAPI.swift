//
//  RSSocketAPI.swift
//  RSSlackCenter
//
//  Created by Reinder de Vries on 12-08-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit
import Starscream
import SwiftyJSON

class RSSocketAPI: NSObject, WebSocketDelegate
{
    /// Singleton instance of `RSSocketAPI`
    static let sharedInstance = RSSocketAPI();
    
    // Reference to the websocket
    var socket:WebSocket?;
    
    // Convenience method
    var isConnected:Bool {
        return self.socket?.isConnected ?? false;
    }
   
    /**
        Connects to websocket with `url`.

        :param: url The URL of the websocket.
    */
    func connect(url:NSURL)
    {
        self.socket = WebSocket(url: url);
        socket?.delegate = self;
        socket?.connect();
    }
    
    /**
        Disconnect from the websocket.
    */
    func disconnect()
    {
        socket?.disconnect();
        socket = nil;
    }
    
    /**
        Send a message over the websocket, formatted as JSON with parameters.

        :param: id Message ID, preferrably incremented from the previous message.
        :param: type Type of the message, see `Slack.type`.
        :param: channelID Channel to send the message on.
        :param: text Actual simple text of the message.
    */
    func sendMessage(id:Int, type:String, channelID:String, text:String)
    {
        var json:JSON = [Slack.param.id: id,
            Slack.param.type: type,
            Slack.param.channel: channelID,
            Slack.param.text: text];
        
        if let string = json.rawString()
        {
            self.send(string);
        }
    }
    
    /**
        Send message over the websocket, as a raw string.
    */
    func send(message:String)
    {
        if let socket = self.socket
        {
            if(!socket.isConnected)
            {
                return;
            }
            
            println(message);
            
            socket.writeString(message);
        }
    }
    
    /**
        Delegate method that's called when an incoming websocket message is received.

        :param: socket The socket it comes from.
        :param: text The text that was received.
    */
    func websocketDidReceiveMessage(socket: WebSocket, text: String)
    {
        println("websocketDidReceiveMessage:: \(text)");
        
        if let dataFromString = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString);
            
            let type = json[Slack.param.type].string;
            let channel = json[Slack.param.channel].string;
            let user = json[Slack.param.user].string;
            let text = json[Slack.param.text].string;
            
            println(type);
            println(channel);
            println(user);
            println(text);
            
            if(channel != RSMessageCenterAPI.sharedInstance.channelID)
            {
                return;
            }
            
            if(type == Slack.type.message)
            {
                var info:[String: String] = [Slack.param.text: text!, Slack.param.user: user!];
                println(info);
                
                NSNotificationCenter.defaultCenter().postNotificationName(MessageCenter.notification.newMessage, object: nil, userInfo: info);
            }
            
            if(type == Slack.type.user_typing)
            {
                NSNotificationCenter.defaultCenter().postNotificationName(MessageCenter.notification.userTyping, object: nil, userInfo: nil);
            }
        }
        
        
    }
    
    /**
        Delegate method that's called when the socket did connect.
    */
    func websocketDidConnect(socket: WebSocket) {
        println("websocket is connected")
    }
    
    /**
        Delegate method that's called when the socket did disconnect.
    */
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        println("websocket is disconnected: \(error?.localizedDescription)")
    }
    
    /**
        Delegate method that's called when the socket receives raw data.
    */
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        println("got some data: \(data.length)")
    }

}
