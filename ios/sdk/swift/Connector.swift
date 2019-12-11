//
//  Connector.swift
//  sdk
//
//  Created by mengxk on 2019/12/5.
//  Copyright © 2019 Elastos. All rights reserved.
//

import ContactSDK

open class Connector {
  private var mPeerNode: PeerNode?
  private var mServiceName: String
  
  private var mMessagListener: PeerNodeListener.MessageListener? = nil
  private var mDataListener: PeerNodeListener.DataListener? = nil
  
  init(serviceName: String) {
    mPeerNode = PeerNode.GetInstance()
    mServiceName = serviceName
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
  
  public func addFriend(friendCode: String, summary: String) -> Int {
    return mPeerNode?.addFriend(friendCode: friendCode, summary: summary) ?? -1
  }

  public func removeFriend(friendCode: String) -> Int {
    return mPeerNode?.removeFriend(friendCode: friendCode) ?? -1
  }

  public func acceptFriend(friendCode: String) -> Int {
    return mPeerNode?.acceptFriend(friendCode: friendCode) ?? -1
  }
  
  public func setFriendInfo(friendCode: String, item: HumanInfo.Item, value: String) -> Int {
    return mPeerNode?.setFriendInfo(friendCode: friendCode, item: item, value: value) ?? -1
  }
  
  public func listFriendInfo() -> [ContactSDK.Contact.FriendInfo]? {
    return mPeerNode?.listFriendInfo() ?? nil
  }
  
  public func listFriendCode() -> [String] {
    return mPeerNode?.listFriendCode() ?? [String]()
  }
  
  public func getStatus() -> ContactStatus {
    return mPeerNode?.getStatus() ?? ContactStatus.Invalid
  }
  
  public func getFriendStatus(friendCode: String) -> ContactStatus {
    return mPeerNode?.getFriendStatus(friendCode: friendCode) ?? ContactStatus.Invalid
  }
  
  public func sendMessage(friendCode: String, message: Contact.Message) -> Int {
    return mPeerNode?.sendMessage(friendCode: friendCode,
                                  message: message) ?? -1
  }
  
}

