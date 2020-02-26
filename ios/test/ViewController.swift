//
//  ViewController.swift
//  test
//
//  Created by mengxk on 2019/9/20.
//  Copyright © 2019 Elastos. All rights reserved.
//

import UIKit
import ContactSDK
import PeerNodeSDK
import CommonCrypto

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    let devId = getDeviceId()
    print("Device ID:" + devId)

    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    mPeerNode = PeerNode.GetInstance(path: cacheDir!.path, deviceId: getDeviceId())

    mPeerNodeListener = {
      class Impl: PeerNodeListener.Listener {
        init(_ vc: ViewController) {
          viewCtrl = vc
        }

        func onAcquire(request: Contact.Listener.AcquireArgs) -> Data? {
          let ret = viewCtrl.processAcquire(request: request)

          var msg = "onAcquire(): req=\(request.toString())\n"
          msg += "onAcquire(): resp=\(String(describing: ret))\n"
          viewCtrl.showEvent(msg)

          return ret
        }

        func onError(errCode: Int, errStr: String, ext: String?) {
          var msg = "\(errCode): \(errStr)"
          msg += "\n\(String(describing: ext))"
          viewCtrl.showError(msg)
        }

        private let viewCtrl: ViewController
      }

      return Impl(self)
    }()
    mPeerNode!.setListener(listener: mPeerNodeListener!)

    mCustomChannelStrategy = {
      class Impl: Contact.ChannelStrategy {
        init() {
          super.init(channelId: Contact.Channel.CustomId.rawValue, name: "LoopMessage")
        }

        override func onSendMessage(humanCode: String, data: Data?) -> Int {
          self.receivedMessage(humanCode: humanCode, data: data)
        }
      }
      return Impl()
    }()
    let cret = mPeerNode!.appendChannelStrategy(channelStrategy: mCustomChannelStrategy!)
    if cret < 0 {
      showError("Failed to call PeerNode.appendChannelStrategy() ret=\(cret)")
      return
    }

    let ret = mPeerNode!.start()
    if(ret < 0) {
      showError("Failed to start PeerNode. ret = \(ret)")
    }
    showMessage("Success to start PeerNode.")

    createConnector()
  }

  private func createConnector() {
    if (mConnector != nil) {
      return;
    }

    mConnector = Connector(serviceName: "test")
    mMsgListener = {
      class Impl: PeerNodeListener.MessageListener {
        init(_ vc: ViewController) {
          viewCtrl = vc
        }

        func onEvent(event: Contact.Listener.EventArgs) {
          viewCtrl.processEvent(event: event)
        }

        func onReceivedMessage(humanCode: String,
                                        channelType: Contact.Channel,
                                        message: Contact.Message) {
          var msg = "onRcvdMsg(): from=\(humanCode)\n"
          if message.type == Contact.Message.Kind.MsgText {
            msg += "onRcvdMsg(): data=\(message.data.toString())\n"
          }
          else if message.type == Contact.Message.Kind.MsgBinary {
            let data = message.data.toData()
            let bytes = [UInt8](data!)
            msg += "onRcvdMsg(): data=\(bytes)\n"
          }
          msg += "onRcvdMsg(): type=\(message.type)\n"
          msg += "onRcvdMsg(): crypto=" + (message.cryptoAlgorithm ?? "nil") + "\n"
          print(msg)
          viewCtrl.showMessage(msg)
        }

        private let viewCtrl: ViewController
      }

      return Impl(self)
    }()
    mConnector!.setMessageListener(listener: mMsgListener!)
  }

  private func sendMessage() {
    if (mConnector == nil) {
      showToast("please create connector first!")
        return
    }

    let friendCodeList = mConnector!.listFriendCode()
    Helper.showFriendList(view: self, friendList: friendCodeList, listener:  { friendCode in
      Helper.showTextSendMessage(view: self, friendCode: friendCode!, listener:  { message in
        let status = self.mConnector!.getFriendStatus(friendCode: friendCode!)
        if(status != Contact.Status.Online) {
          self.showMessage(ViewController.ErrorPrefix + "Friend is not online.")
          return
        }

        let ret = self.mConnector!.sendMessage(friendCode: friendCode!, channel: Contact.Channel.Carrier,
                                               message: message!)
        if(ret < 0) {
          self.showMessage(ViewController.ErrorPrefix + "Failed to send message to " + friendCode!)
        }
      })
    })

  }

  private func sendBinaryMessage() {
    if (mConnector == nil) {
      showToast("please create connector first!")
      return
    }

    let friendCodeList = mConnector!.listFriendCode()
    Helper.showFriendList(view: self, friendList: friendCodeList, listener:  { friendCode in
      let status = self.mConnector!.getFriendStatus(friendCode: friendCode!)
      if(status != Contact.Status.Online) {
        self.showMessage(ViewController.ErrorPrefix + "Friend is not online.")
        return
      }

      let data = Data.init([25, 33, 88, 0, 254, 2])
      let ret = self.mConnector!.sendBinaryMessage(friendCode: friendCode!, channel: Contact.Channel.Carrier,
                                             message: data)
      if(ret < 0) {
        self.showMessage(ViewController.ErrorPrefix + "Failed to send binary message to " + friendCode!)
      }
    })

  }

  private func sendLoopMessage() {
    if (mConnector == nil) {
      showToast("please create connector first!")
      return
    }
    let info = mPeerNode!.getUserInfo()
    if info == nil {
      showToast("Failed to get user info.")
      return
    }

    let ret = mConnector!.sendMessage(friendCode: info!.humanCode!,
                                    channel: mCustomChannelStrategy!.getChannel(),
                                    message: "test loop message")
    if(ret < 0) {
      showToast("Failed to call testLoopMessage() ret=\(ret)")
    }
  }

    private func requestToAddFriend() {
        print("*** requestToAddFriend()")

        var friendCodeInput = ""

        let alert = UIAlertController(title: "Friend Code", message: "Please type a friend code", preferredStyle: .alert)

        alert.addTextField { (textField) in
//            textField.text = self.mCarrierAddress2
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            friendCodeInput = (alert?.textFields![0].text)! // Force unwrapping because we know it exists.

            print("friend code input: \(friendCodeInput)")
            let ret = self.mPeerNode!.addFriend(friendCode: friendCodeInput, summary: "{\"serviceName\":\"test\",\"content\":\"hello\"}")
            print("ret: \(ret)")
        }))

        self.present(alert, animated: true, completion: nil)
    }

  @IBAction func onOptionsMenuTapped(_ sender: Any) {
    optionsMenu.isHidden = !optionsMenu.isHidden
  }

  @IBAction func onOptionsItemSelected(_ sender: UIButton) {
    optionsMenu.isHidden = true

    enum ButtonTag: Int {
      case create_service = 100
      case send_msg = 101
      case add_friend = 102
      case send_bin_msg = 103
      case send_loop_msg = 104
    }

    switch sender.tag {
    case ButtonTag.create_service.rawValue:
      createConnector()
      break
    case ButtonTag.send_msg.rawValue:
      sendMessage()
      break
    case ButtonTag.add_friend.rawValue:
      requestToAddFriend()
      break
    case ButtonTag.send_bin_msg.rawValue:
      sendBinaryMessage()
      break
    case ButtonTag.send_loop_msg.rawValue:
      sendLoopMessage()
      break
    default:
      fatalError("Button [\(sender.currentTitle!)(\(sender.tag))] not decleared.")
    }
  }

  private func processAcquire(request: Contact.Listener.AcquireArgs) -> Data? {
    var response: Data?

    switch (request.type) {
      case .PublicKey:
        response = mPublicKey.data(using: .utf8)
        break
      case .EncryptData:
        response = request.data // plaintext
        break
      case .DecryptData:
        response = request.data // plaintext
        break
      case .DidPropAppId:
        // do nothing
        break
      case .DidAgentAuthHeader:
        response = getAgentAuthHeader()
        break
      case .SignData:
        response = signData(data: request.data)
        break
    }

    return response
  }

  private func processEvent(event: Contact.Listener.EventArgs) {
    switch (event.type) {
      case .StatusChanged:
        let statusEvent = event as! Contact.Listener.StatusEvent
        let msg = event.humanCode + " status changed: " + statusEvent.status.toString()
        showEvent(msg)
        break
      case .FriendRequest:
        let requestEvent = event as! Contact.Listener.RequestEvent
        Helper.showFriendRequest(view: self,
                                 humanCode: requestEvent.humanCode, summary: requestEvent.summary,
                                 listener: { _ in
          let ret = self.mConnector!.acceptFriend(friendCode: requestEvent.humanCode)
          if(ret < 0) {
            self.showMessage(ViewController.ErrorPrefix + "Failed to acceptFriend \(requestEvent.humanCode). ret=\(ret)")
          }
        })
        break
      case .HumanInfoChanged:
        let infoEvent = event as! Contact.Listener.InfoEvent
        let msg = event.humanCode + " info changed: " + infoEvent.toString()
        showEvent(msg)
        break
    }
  }

  private func getAgentAuthHeader() -> Data {
    let appid = "org.elastos.debug.didplugin"
    //let appkey = "b2gvzUM79yLhCbbGNWCuhSsGdqYhA7sS"
    let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    let auth = getMD5Sum(str: "appkey\(timestamp)")
    let headerValue = "id=\(appid)time=\(timestamp)auth=\(auth)"
    print("getAgentAuthHeader() headerValue=" + headerValue)

    return headerValue.data(using: .utf8)!
  }

  private func signData(data: Data?) -> Data? {
    if data == nil {
      return nil
    }

    var signedData = Data()
    let ret = Contact.Debug.Keypair.Sign(privateKey: mPrivateKey, data: data!, signedData: &signedData)
    if(ret < 0) {
      showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.Sign()")
      return nil
    }

    return signedData
  }

  private func getDeviceId() -> String {
    let devId = UIDevice.current.identifierForVendor?.uuidString
    return devId!
  }
  
  private func getMD5Sum(str: String) -> String {
    let length = Int(CommonCrypto.CC_MD5_DIGEST_LENGTH)
    let messageData = str.data(using: .utf8)!
    var digestData = Data(count: length)
    
    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
      messageData.withUnsafeBytes { messageBytes -> UInt8 in
        if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
          let messageLength = CC_LONG(messageData.count)
          CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
        }
        return 0
      }
    }
    return digestData.map { String(format: "%02hhx", $0) }.joined()
  }
  
  private func showMessage(_ msg: String) {
    print(msg)
    
    DispatchQueue.main.async { [weak self] in
      self?.msgLog.text = msg
    }

    if msg.hasPrefix(ViewController.ErrorPrefix) {
      showToast(msg)
    }
  }

  private func showEvent(_ newMsg: String) {
    print(newMsg)
    DispatchQueue.main.async { [weak self] in
      self?.eventLog.text += "\n"
      self?.eventLog.text += newMsg
    }
  }

  private func showError(_ newErr: String) {
    print(newErr)

    DispatchQueue.main.async { [weak self] in
      self?.errLog.text = newErr
    }
  }

  private func showToast(_ message : String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.view.backgroundColor = UIColor.black
    alert.view.alpha = 0.6
    alert.view.layer.cornerRadius = 15

    DispatchQueue.main.async { [weak self] in
      self?.present(alert, animated: false)
    }

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
      alert.dismiss(animated: true)
    }
  }
//
//  private func isEnglishWords(_ words: String?) -> Bool {
//    guard (words?.count ?? -1) > 0 else {
//      return false
//    }
//
//    let isEnglish = (words!.range(of: "[^a-zA-Z ]", options: .regularExpression) == nil)
//    return isEnglish
//  }

  @IBOutlet weak var optionsMenu: UIScrollView!
  @IBOutlet weak var errLog: UITextView!
  @IBOutlet weak var msgLog: UITextView!
  @IBOutlet weak var eventLog: UITextView!

//  private var mCacheDir: URL?

  // DID 1
//  private let mSavedMnemonic = "advance script timber immense increase gap wedding message awkward vote melt destroy"
  private let mPublicKey = "020ef0472d42c9779961b88cb38ba65e270102cf6e9e1f67f1574c63cbdc0ca81b"
  private let mPrivateKey = "f66583200f6e5dff023a323d07c8c4e5925572a056ea28930822ab56429a44d4"
//  private let mCarrierAddress = "9N3C8AuXfEHXvWGz5VR9nU8rN3n32XhtG3NW2X54KKF7tVan2NVG"
//  private let mDID = "iqyzac2ZZh6NRmUWC8zUrvZ2rfntDo6PJe"

//  private let mCarrierAddress2 = "MD7RNZMEmt134yWjp3byby5RtsxPJkBqEZcgHRVtCPmB9cuu4u3M"
//  private let mDID2 = "iemYy4qMieiZzJDb7uZDvEDnvko8yepN2y"
//    private let mPublicKey = "02ce1e16f2e0f584cc0cca8354ebe703049eb8317f503d836a7d91744754ca0469"
//    private let mPrivateKey = "3e444ded5c1ee80f1cc3b5845cac4cb4d72f0f5a7cb31882a2950902753b3e1a"

/*
    // DID 2
    private let mSavedMnemonic = "shoot island position soft burden budget tooth cruel issue economy destroy above"
    private let mPublicKey = "024bd8342acbfac4582705e93b573f5c01de16425b7f42f3d9f8892cefe32fa7af"
    private let mPrivateKey = "1daf5ce87ed1114ed9f6e3417b4c3031ce048ece44c286d3c646a2ecee9c40a4"
    private let mCarrierAddress = "MD7RNZMEmt134yWjp3byby5RtsxPJkBqEZcgHRVtCPmB9cuu4u3M"
    private let mDID = "iemYy4qMieiZzJDb7uZDvEDnvko8yepN2y"

    private let mCarrierAddress2 = "9N3C8AuXfEHXvWGz5VR9nU8rN3n32XhtG3NW2X54KKF7tVan2NVG"
    private let mDID2 = "igHshxN1dApFu2y7xCDyQenpiYJ8Cjc9XA"
*/

  private var mPeerNode: PeerNode?
  private var mPeerNodeListener: PeerNodeListener.Listener?
//  private var mContactDataListener: Contact.DataListener?
//
  private var mConnector: Connector?
  private var mMsgListener: PeerNodeListener.MessageListener?

  private var mCustomChannelStrategy: Contact.ChannelStrategy?


//  private var mContactRecvFileMap = [String: Contact.Message.FileData]()
//  private var mContactSendFileMap = [String: String]()
//
  private static let KeypairLanguage = "english"
  private static let KeypairWords = ""
  private static let SavedMnemonicKey = "mnemonic"
  private static let ErrorPrefix = "Error: "
  private static let TAG = "ContactTest"

}

