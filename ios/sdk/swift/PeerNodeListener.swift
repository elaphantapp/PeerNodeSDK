//
//  PeerListener.swift
//  sdk
//
//  Created by mengxk on 2019/12/9.
//  Copyright © 2019 Elastos. All rights reserved.
//

import Foundation
import ContactSDK

protocol FileInformationProviderDelegate { }

public protocol PeerNodeListenerListener: class {
    func onAcquire(request: Contact.Listener.AcquireArgs) -> Data?
    
    func onError(errCode: Int,
                 errStr: String,
                 ext: String?)
}


public protocol PeerNodeListenerMessageListener: class {
    func onEvent(event: Contact.Listener.EventArgs)

    func onReceivedMessage(humanCode: String,
                           channelType: Contact.Channel,
                           message: Contact.Message)
}

public protocol PeerNodeListenerDataListener: class {
    func onNotify(humanCode: String,
                  channelType: Contact.Channel,
                  dataId: String,
                  status: Contact.DataListener.Status)

    func onReadData(humanCode: String,
                    channelType: Contact.Channel,
                    dataId: String,
                    offset: Int64,
                    data: inout Data?) -> Int

    func onWriteData(humanCode: String,
                     channelType: Contact.Channel,
                     dataId: String,
                     offset: Int64,
                     data: Data?) -> Int
}

open class PeerNodeListener {
    public typealias Listener = PeerNodeListenerListener
    weak var listener: Listener?

    public typealias MessageListener = PeerNodeListenerMessageListener
    weak var messageListener: MessageListener?

    public typealias DataListener = PeerNodeListenerDataListener
    weak var dataListener: DataListener?
}
