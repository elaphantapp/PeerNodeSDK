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
  public class Listener {
    open func onAcquire(request: AcquireArgs) -> Data? {
      fatalError("\(#function) not implementation.")
    }
    
    open func onError(errCode: Int, errStr: String, ext: String?) {
      fatalError("\(#function) not implementation.")
    }
  }
  
  public class MessageListener {
    open func onEvent(event: Contact.Listener.EventArgs) {
      fatalError("\(#function) not implementation.")
    }
    open func onReceivedMessage(humanCode: String, channelType: ContactChannel,
                                message: Contact.Message) {
      fatalError("\(#function) not implementation.")
    }
  }
  
  public class DataListener {
    open func onNotify(humanCode: String, channelType: ContactChannel, dataId: String,
                       status: Contact.DataListener.Status) {
      fatalError("\(#function) not implementation.")
    }
    open func onReadData(humanCode: String, channelType: ContactChannel, dataId: String,
                         offset: Int64, data: inout Data?) -> Int {
      fatalError("\(#function) not implementation.")
    }
    open func onWriteData(humanCode: String, channelType: ContactChannel, dataId: String,
                          offset: Int64, data: Data?) -> Int {
      fatalError("\(#function) not implementation.")
    }
  }
}
