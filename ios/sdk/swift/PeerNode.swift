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
  public static let CHAT_SERVICE_NAME = "chat";
  public static let PROTOCOL_APPEND_DATA = Data.init([0xC3, 0x83, 0xC3, 0x83, 0xC3, 0x83, 0xC3, 0x83])
  
  private var mContact: Contact
  private var mListener: PeerNodeListener.Listener? = nil
  private var mMessageListeners = [String: [PeerNodeListener.MessageListener]]()
  private var mDataListeners = [String: [PeerNodeListener.DataListener]]()

  public static func WithLock(lock: Any?, f: () -> Void) {
    objc_sync_enter(lock ?? self)
    f()
    objc_sync_exit(lock ?? self)
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
            print("xxxxxxxxxxxxxxxxxxxxxxxxxxxx")
            return
          }
          
          if (event.type == EventArgs.Kind.FriendRequest) {
            PeerNode.WithLock(lock: peerNode.mMessageListeners) {
              let requestEvent = event as! Contact.Listener.RequestEvent
              let listeners = peerNode.findMsgListener(summary: requestEvent.summary)
              if (listeners.lis == nil) {
                return
              }

              let args = RequestEvent(type: event.type.rawValue, humanCode: event.humanCode,
                                      channelType: event.channelType.rawValue,
                                      data: listeners.content!.data(using: String.Encoding.utf8))
              for listener in listeners.lis! {
                listener.onEvent(event: args)
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

        override func onReceivedMessage(humanCode: String, channelType: Contact.Channel, message: Contact.Message) {
          var msg = "onRcvdMsg(): data=\(message.data.toString())\n"
          msg += "onRcvdMsg(): type=\(message.type)\n"
          msg += "onRcvdMsg(): crypto=" + (message.cryptoAlgorithm ?? "nil") + "\n"
          print("\(msg)")

          if(message.type == Contact.Message.Kind.MsgText) {
            PeerNode.WithLock(lock: peerNode.mMessageListeners) {
              let listeners = peerNode.findMsgListener(summary: message.data.toString())
              if (listeners.lis == nil) {
                return
              }
              
              for listener in listeners.lis! {
                listener.onReceivedMessage(humanCode: humanCode, channelType: channelType, message: Contact.MakeTextMessage(text: listeners.content!, cryptoAlgorithm: nil, memo: nil))
              }
            }
          }
          else if (message.type == Contact.Message.Kind.MsgBinary) {
            let data = message.data.toData()
            peerNode.distributeBinary(humanCode: humanCode, channelType: channelType, data: data!)
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

        override func onNotify(humanCode: String, channelType: Contact.Channel, dataId: String,
                               status: Status) {
          let msg = "onNotify(): dataId=\(dataId), status=\(status)\n";
          print("\(msg)")
        }

        override func onReadData(humanCode: String, channelType: Contact.Channel, dataId: String,
                                 offset: Int64, data: inout Data?) -> Int {
          return 0
        }

        override func onWriteData(humanCode: String, channelType: Contact.Channel, dataId: String,
                                  offset: Int64, data: Data?) -> Int {
          return 0
        }

        private let peerNode: PeerNode
      }

      return Impl(self)
    }()
    mContact.setDataListener(listener: contactDataListener)
  }
  
  private func findMsgListener(summary: String) -> (lis: [PeerNodeListener.MessageListener]?, content: String?) {
    var lis: [PeerNodeListener.MessageListener]? = nil
    var content: String?

    PeerNode.WithLock(lock: self) {
      do {
        let data = summary.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let name = (json as? [String: AnyObject])?["serviceName"] as? String
        content = (json as? [String: AnyObject])?["content"] as? String
        if (name != nil) {
          lis = mMessageListeners[name!.lowercased()]
        }
      } catch {
        print("parse json failed\n");
      }
    
      if (lis == nil) {
        content = summary
        lis = mMessageListeners["chat"]
      }
    }
    
    return (lis, content)
  }

  private func distributeBinary(humanCode: String, channelType: Contact.Channel, data: Data) {
    let range = data.range(of: PeerNode.PROTOCOL_APPEND_DATA)
    PeerNode.WithLock(lock: mMessageListeners) {
      var lis: [PeerNodeListener.MessageListener]?
      if range != nil {
        let json = data.subdata(in: 0..<range!.first!)
        do {
          let json = try JSONSerialization.jsonObject(with: json, options: .allowFragments)
          let name = (json as? [String: AnyObject])?["serviceName"] as? String
          if (name != nil) {
            lis = mMessageListeners[name!.lowercased()]
            if lis != nil {
              let content = data.subdata(in: (range!.first! + PeerNode.PROTOCOL_APPEND_DATA.count)..<data.count)
              for listener in lis! {
                listener.onReceivedMessage(humanCode: humanCode, channelType: channelType,
                                           message: Contact.MakeBinaryMessage(data: content, cryptoAlgorithm: nil, memo: nil))
              }
              return
            }
          }
        } catch {
          print("parse json failed\n");
        }
      }

      lis = mMessageListeners["chat"]
      if lis == nil {
        return
      }
      for listener in lis! {
        listener.onReceivedMessage(humanCode: humanCode, channelType: channelType,
                                   message: Contact.MakeBinaryMessage(data: data, cryptoAlgorithm: nil, memo: nil))
      }
    }
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

  public func appendChannelStrategy(channelStrategy: Contact.ChannelStrategy) -> Int {
      return mContact.appendChannelStrategy(channelStrategy: channelStrategy)
  }
  
  public func setUserInfo(item: Contact.UserInfo.Item, value: String) -> Int {
    return mContact.setUserInfo(item: item, value: value)
  }
  public func getUserInfo() -> Contact.UserInfo? {
    return mContact.getUserInfo()
  }

  public func getUserBrief(brief: inout String) -> Int {
    return mContact.getUserBrief(brief: &brief)
  }
  
  public func setIdentifyCode(type: Contact.UserInfo.Kind, value: String) -> Int {
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
  
  public func setFriendInfo(friendCode: String, item: Contact.HumanInfo.Item, value: String) -> Int {
    return mContact.setHumanInfo(humanCode: friendCode, item: item, value: value);
  }
  
  public func listFriendInfo() -> [ContactSDK.Contact.FriendInfo]? {
    return mContact.listFriendInfo()
  }
  
  public func listFriendCode() -> [String]? {
    return mContact.listFriendCode()
  }
  
  public func getStatus() -> Contact.Status? {
    return mContact.getStatus(humanCode: "-user-info-")
  }
  
  public func getFriendStatus(friendCode: String) -> Contact.Status? {
    return mContact.getStatus(humanCode: friendCode)
  }
  
  public func sendMessage(friendCode: String, channel: Contact.Channel, message: Contact.Message) -> Int {
    return mContact.sendMessage(friendCode: friendCode,
                                channelType: channel,
                                message: message)
  }
  
  public func pullFileAsync(friendCode: String, fileInfo: Contact.Message.FileData) -> Int {
    return mContact.pullFileAsync(friendCode: friendCode,
                                  channelType: Contact.Channel.Carrier,
                                  fileInfo: fileInfo)
  }
  
  public func cancelPullFile(friendCode: String, fileInfo: Contact.Message.FileData) -> Int {
    return mContact.cancelPullFile(friendCode: friendCode,
                                   channelType: Contact.Channel.Carrier,
                                   fileInfo: fileInfo)
  }
  
  public func setWalletAddress(name: String, value: String) -> Int {
    return mContact.setWalletAddress(name: name, value: value)
  }

  public func exportUserData(toFile: String) -> Int {
      return mContact.exportUserData(toFile: toFile);
  }

  public func importUserData(fromFile: String) -> Int {
      return mContact.importUserData(fromFile: fromFile);
  }
}

extension ContactSDK.Contact.Status {
    public func toString() -> String {
        switch self {
        case .Invalid:
            return "Invalid"
        case .WaitForAccept:
            return "WaitForAccept"
        case .Offline:
            return "Offline"
        case .Online:
            return "Online"
        case .Removed:
            return "Removed"
        }
    }
}
