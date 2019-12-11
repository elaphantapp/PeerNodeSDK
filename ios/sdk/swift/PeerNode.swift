//
//  PeerNode.swift
//  sdk
//
//  Created by mengxk on 2019/12/5.
//  Copyright © 2019 Elastos. All rights reserved.
//

import Foundation
import ContactSDK

open class PeerNode {  
  static var sInstance: PeerNode?

  private var mContact: Contact
  private var mListener: PeerNodeListener.Listener? = nil
  private var mMessageListeners = [String: [PeerNodeListener.MessageListener]]()
  private var mDataListeners = [String: [PeerNodeListener.DataListener]]()

  public static func WithLock(lock: Any?, f: () -> Void) {
    objc_sync_enter(lock ?? self)
    f()
    objc_sync_enter(lock ?? self)
  }
  
  init (path: String, deviceId: String) {
    Contact.Factory.SetLogLevel(level: 7)
    Contact.Factory.SetDeviceId(devId: deviceId)
    _ = Contact.Factory.SetLocalDataDir(dir: path)
    
    mContact = Contact.Factory.Create()
    let contactListener: Contact.Listener = {
      class Impl: Contact.Listener {
        init(_ node: PeerNode) {
          peerNode = node
          super.init()
        }
        
        override func onAcquire(request: AcquireArgs) -> Data? {
          var ret: Data?
          PeerNode.WithLock(lock: peerNode.mListener) {
            ret = peerNode.mListener?.onAcquire(request: request)
          }
          return ret
        }

        override func onEvent(event: EventArgs) {
          if (peerNode.mMessageListeners.count == 0) {
            return
          }
          
          if (event.type == EventArgs.Kind.FriendRequest) {
            PeerNode.WithLock(lock: peerNode.mMessageListeners) {
              let requestEvent = event as! Contact.Listener.RequestEvent
              let listeners = peerNode.findMsgListener(summary: requestEvent.summary)
              if (listeners == nil) {
                return
              }
              
              for listener in listeners! {
                listener.onEvent(event: event)
              }
            }
          } else {
            PeerNode.WithLock(lock: peerNode.mMessageListeners) {
              for (_, listeners) in peerNode.mMessageListeners {
                for listener in listeners {
                  listener.onEvent(event: event)
                }
              }
            }
          }
        }

        override func onReceivedMessage(humanCode: String, channelType: Int, message: Contact.Message) {
          var msg = "onRcvdMsg(): data=\(message.data.toString())\n"
          msg += "onRcvdMsg(): type=\(message.type)\n"
          msg += "onRcvdMsg(): crypto=" + (message.cryptoAlgorithm ?? "nil") + "\n"
          print("\(msg)")

          if(message.type == Contact.Message.Kind.MsgText) {
            PeerNode.WithLock(lock: peerNode.mMessageListeners) {
              let listeners = peerNode.findMsgListener(summary: message.data.toString())
              if (listeners == nil) {
                return
              }
              
              for listener in listeners! {
                listener.onReceivedMessage(humanCode: humanCode, channelType: ContactChannel(rawValue: channelType)!, message: message)
              }
            }
          }
        }

        override func onError(errCode: Int32, errStr: String, ext: String?) {
          var msg = "\(errCode): \(errStr)"
          msg += "\n\(String(describing: ext))"
          print("\(msg)")
          
          PeerNode.WithLock(lock: peerNode.mListener) {
            peerNode.mListener?.onError(errCode: Int(errCode), errStr: errStr, ext: ext)
          }
        }
        
        private let peerNode: PeerNode
      }

      return Impl(self)
    }()
    mContact.setListener(listener: contactListener)
    
    let contactDataListener: Contact.DataListener = {
      class Impl: Contact.DataListener {
        init(_ node: PeerNode) {
          peerNode = node
          super.init()
        }

        override func onNotify(humanCode: String, channelType: ContactChannel, dataId: String,
                               status: Status) {
          let msg = "onNotify(): dataId=\(dataId), status=\(status)\n";
          print("\(msg)")
        }

        override func onReadData(humanCode: String, channelType: ContactChannel, dataId: String,
                                 offset: Int64, data: inout Data?) -> Int {
          return 0
        }

        override func onWriteData(humanCode: String, channelType: ContactChannel, dataId: String,
                                  offset: Int64, data: Data?) -> Int {
          return 0
        }

        private let peerNode: PeerNode
      }

      return Impl(self)
    }()
    mContact.setDataListener(listener: contactDataListener)
  }
  
  private func findMsgListener(summary: String) -> [PeerNodeListener.MessageListener]? {
    var lis: [PeerNodeListener.MessageListener]? = nil
    
    PeerNode.WithLock(lock: self) {
      do {
        let data = summary.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let name = (json as? [String: AnyObject])?["serviceName"] as? String
        if (name != nil) {
          lis = mMessageListeners[name!.lowercased()]
        }
      } catch {
        print("parse json failed\n");
      }
    
      if (lis == nil) {
        lis = mMessageListeners["elaphantchat"]
      }
    }
    
    return lis
  }
  
  // create instance if sInstance is null.
  static public func GetInstance(path: String, deviceId: String) -> PeerNode {
    if (sInstance == nil) {
      sInstance = PeerNode(path: path, deviceId: deviceId)
    }

    return sInstance!
  }
  //do not create instance, just return sInstance.
  static public func GetInstance() -> PeerNode {
    return sInstance!
  }
  
  public func setListener(listener: PeerNodeListener.Listener) {
    mListener = listener
  }

  public func addMessageListener(serviceName: String, listener: PeerNodeListener.MessageListener) {
    PeerNode.WithLock(lock: mMessageListeners) {
      let name = serviceName.lowercased()
      var listeners = mMessageListeners[name]
      if (listeners == nil) {
        listeners = [PeerNodeListener.MessageListener]()
      }
      listeners!.append(listener)
      mMessageListeners[name] = listeners
    }
  }
  public func removeMessageListener(serviceName: String, listener: PeerNodeListener.MessageListener) {
     PeerNode.WithLock(lock: mMessageListeners) {
      let name = serviceName.lowercased()
      var listeners = mMessageListeners[name]
      if (listeners == nil) {
        return
      }
      listeners = listeners!.filter() { $0 !== listener }
      if (listeners!.count <= 0) {
          mMessageListeners[name] = nil
      } else {
          mMessageListeners[name] = listeners
      }
    }
  }

  public func addDataListener(serviceName: String, listener: PeerNodeListener.DataListener) {
    PeerNode.WithLock(lock: mDataListeners) {
      let name = serviceName.lowercased()
      var listeners = mDataListeners[name]
      if (listeners == nil) {
        listeners = [PeerNodeListener.DataListener]()
      }
      listeners!.append(listener)
      mDataListeners[name] = listeners
    }
  }
  public func removeDataListener(serviceName: String, listener: PeerNodeListener.DataListener) {
     PeerNode.WithLock(lock: mDataListeners) {
      let name = serviceName.lowercased()
      var listeners = mDataListeners[name]
      if (listeners == nil) {
        return
      }
      listeners = listeners!.filter() { $0 !== listener }
      if (listeners!.count <= 0) {
          mMessageListeners[name] = nil
      } else {
          mDataListeners[name] = listeners
      }
    }
  }
  
  public func start() -> Int {
    let ret = mContact.start();
    _ = mContact.syncInfoDownloadFromDidChain()
    _ = mContact.syncInfoUploadToDidChain()
    return ret
  }
  public func stop() -> Int {
    return mContact.stop()
  }
  
  public func setUserInfo(item: HumanInfo.Item, value: String) -> Int {
    return mContact.setUserInfo(item: item, value: value)
  }
  public func getUserInfo() -> Contact.UserInfo? {
    return mContact.getUserInfo()
  }
  
  public func setIdentifyCode(type: ContactSDK.IdentifyCode.Kind, value: String) -> Int {
    return mContact.setIdentifyCode(type: type, value: value)
  }
  
  public func addFriend(friendCode: String, summary: String) -> Int {
    return mContact.addFriend(friendCode: friendCode, summary: summary)
  }

  public func removeFriend(friendCode: String) -> Int {
    return mContact.removeFriend(friendCode: friendCode)
  }

  public func acceptFriend(friendCode: String) -> Int {
    return mContact.acceptFriend(friendCode: friendCode)
  }
  
  public func setFriendInfo(friendCode: String, item: HumanInfo.Item, value: String) -> Int {
    return mContact.setHumanInfo(humanCode: friendCode, item: item, value: value);
  }
  
  public func listFriendInfo() -> [ContactSDK.Contact.FriendInfo]? {
    return mContact.listFriendInfo()
  }
  
  public func listFriendCode() -> [String]? {
    return mContact.listFriendCode()
  }
  
  public func getStatus() -> ContactStatus? {
    return mContact.getStatus(humanCode: "-user-info-")
  }
  
  public func getFriendStatus(friendCode: String) -> ContactStatus? {
    return mContact.getStatus(humanCode: friendCode)
  }
  
  public func sendMessage(friendCode: String, message: Contact.Message) -> Int {
    return mContact.sendMessage(friendCode: friendCode,
                                 channelType: ContactChannel.Carrier,
                                 message: message)
  }
  
  public func pullFileAsync(friendCode: String, fileInfo: Contact.Message.FileData) -> Int {
    return mContact.pullFileAsync(friendCode: friendCode,
                                  channelType: ContactChannel.Carrier,
                                  fileInfo: fileInfo)
  }
  
  public func cancelPullFile(friendCode: String, fileInfo: Contact.Message.FileData) -> Int {
    return mContact.cancelPullFile(friendCode: friendCode,
                                   channelType: ContactChannel.Carrier,
                                   fileInfo: fileInfo)
  }
  
  public func setWalletAddress(name: String, value: String) -> Int {
    return mContact.setWalletAddress(name: name, value: value)
  }
}
