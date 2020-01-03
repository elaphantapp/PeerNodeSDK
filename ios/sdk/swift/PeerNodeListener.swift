//
//  PeerListener.swift
//  sdk
//
//  Created by mengxk on 2019/12/9.
//  Copyright © 2019 Elastos. All rights reserved.
//

import Foundation
import ContactSDK

open class PeerNodeListener {
  open class Listener {
    public init() { }
    
    open func onAcquire(request: Contact.Listener.AcquireArgs) -> Data? {
      fatalError("\(#function) not implementation.")
    }
    
    open func onError(errCode: Int, errStr: String, ext: String?) {
      fatalError("\(#function) not implementation.")
    }
  }
  
  open class MessageListener {
    public init() { }
    
    open func onEvent(event: Contact.Listener.EventArgs) {
      fatalError("\(#function) not implementation.")
    }
    open func onReceivedMessage(humanCode: String, channelType: Contact.Channel,
                                message: Contact.Message) {
      fatalError("\(#function) not implementation.")
    }
  }
  
  open class DataListener {
    public init() { }
    
    open func onNotify(humanCode: String, channelType: Contact.Channel, dataId: String,
                       status: Contact.DataListener.Status) {
      fatalError("\(#function) not implementation.")
    }
    open func onReadData(humanCode: String, channelType: Contact.Channel, dataId: String,
                         offset: Int64, data: inout Data?) -> Int {
      fatalError("\(#function) not implementation.")
    }
    open func onWriteData(humanCode: String, channelType: Contact.Channel, dataId: String,
                          offset: Int64, data: Data?) -> Int {
      fatalError("\(#function) not implementation.")
    }
  }
}
