//
//  Connector.swift
//  sdk
//
//  Created by mengxk on 2019/12/5.
//  Copyright © 2019 Elastos. All rights reserved.
//

import Foundation
import ContactSDK

open class Connector {
  private var mPeerNode: PeerNode?
  private var mServiceName: String
  
  private var mMessagListener: PeerNodeListener.MessageListener? = nil
  private var mDataListener: PeerNodeListener.DataListener? = nil
  
  public init(serviceName: String?) {
    mPeerNode = PeerNode.GetInstance()
    if (serviceName == nil || serviceName!.isEmpty) {
        mServiceName = PeerNode.CHAT_SERVICE_NAME;
    } else {
        mServiceName = serviceName!;
    }
  }
  
  deinit {
    removeMessageListener()
    removeDataListener()
  }
  
  public func setMessageListener(listener: PeerNodeListener.MessageListener) {
    if (mPeerNode == nil) {
      return
    }
    if (mMessagListener != nil) {
      removeMessageListener()
    }
    mPeerNode?.addMessageListener(serviceName: mServiceName, listener: listener)
    mMessagListener = listener
  }
  
  public func removeMessageListener() {
    if (mPeerNode == nil
    || mMessagListener == nil) {
      return
    }
    mPeerNode?.removeMessageListener(serviceName: mServiceName, listener: mMessagListener!)
    mMessagListener = nil
  }
  
  public func setDataListener(listener: PeerNodeListener.DataListener) {
    if (mPeerNode == nil) {
      return
    }
    if (mDataListener != nil) {
        removeDataListener()
    }
    mPeerNode?.addDataListener(serviceName: mServiceName, listener: listener)
    mDataListener = listener
  }
  
  public func removeDataListener() {
    if (mPeerNode == nil
    || mDataListener == nil) {
      return
    }
    mPeerNode?.removeDataListener(serviceName: mServiceName, listener: mDataListener!)
    mDataListener = nil
  }
  
  public func getUserInfo() -> Contact.UserInfo? {
      return mPeerNode?.getUserInfo()
  }
  
  public func addFriend(friendCode: String, summary: String) -> Int {
    if (mPeerNode == nil) {
      return -1
    }

    do {
      let data = [
        "serviceName": mServiceName,
        "content": summary,
      ]
      let encode = try JSONEncoder().encode(data)
      let val = String(data: encode, encoding: .utf8)!
      return mPeerNode!.addFriend(friendCode: friendCode, summary: val)
    } catch {
      print("make json failed\n")
    }
    
    return -1
  }

  public func removeFriend(friendCode: String) -> Int {
    return mPeerNode?.removeFriend(friendCode: friendCode) ?? -1
  }

  public func acceptFriend(friendCode: String) -> Int {
    return mPeerNode?.acceptFriend(friendCode: friendCode) ?? -1
  }
  
  public func setFriendInfo(friendCode: String, item: Contact.HumanInfo.Item, value: String) -> Int {
    return mPeerNode?.setFriendInfo(friendCode: friendCode, item: item, value: value) ?? -1
  }
  
  public func listFriendInfo() -> [ContactSDK.Contact.FriendInfo]? {
    return mPeerNode?.listFriendInfo() ?? nil
  }
  
  public func listFriendCode() -> [String] {
    return mPeerNode?.listFriendCode() ?? [String]()
  }
  
  public func getStatus() -> Contact.Status {
    return mPeerNode?.getStatus() ?? Contact.Status.Invalid
  }
  
  public func getFriendStatus(friendCode: String) -> Contact.Status {
    return mPeerNode?.getFriendStatus(friendCode: friendCode) ?? Contact.Status.Invalid
  }
  
  public func sendMessage(friendCode: String, channel: Contact.Channel, message: String) -> Int {
   if (mPeerNode == nil) {
     return -1
   }

    var data: String
    let isDidFriend = ContactSDK.Contact.IsDidFriend(friendCode: friendCode)
    if (isDidFriend) {
     do {
       let json = [
         "serviceName": mServiceName,
         "content": message,
       ]
       let encode = try JSONEncoder().encode(json)
       data = String(data: encode, encoding: .utf8)!
     } catch {
       print("make json failed\n")
       return -1
     }
    } else {
      data = message
    }
   
    return mPeerNode!.sendMessage(friendCode: friendCode, channel: channel,
                                  message: Contact.MakeTextMessage(text: data, cryptoAlgorithm: nil, memo: nil))
  }
  
  public func sendBinaryMessage(friendCode: String, channel: Contact.Channel, message: Data) -> Int {
    if (mPeerNode == nil) {
      return -1
    }

    var data: Data
    let isDidFriend = ContactSDK.Contact.IsDidFriend(friendCode: friendCode)
    if (isDidFriend) {
     do {
       let json = [
         "serviceName": mServiceName,
         "content": "binary",
       ]
       let encode = try JSONEncoder().encode(json)
       let str = String(data: encode, encoding: .utf8)!
       data = str.data(using: String.Encoding.utf8)!
       data.append(PeerNode.PROTOCOL_APPEND_DATA)
       data.append(message)
     } catch {
       print("make json failed\n")
       return -1
     }
    } else {
      data = message
    }

    return mPeerNode!.sendMessage(friendCode: friendCode, channel: channel,
                                  message: Contact.MakeBinaryMessage(data: data, cryptoAlgorithm: nil, memo: nil))
  }

}

