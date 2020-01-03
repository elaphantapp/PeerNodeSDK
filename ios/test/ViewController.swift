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

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    let devId = getDeviceId()
    Log.i(tag: ViewController.TAG, msg: "Device ID:" + devId)

    mSavedMnemonic = UserDefaults.standard.string(forKey: ViewController.SavedMnemonicKey)
    if mSavedMnemonic == nil {
      var mnem = String()
      let ret = Contact.Debug.Keypair.GenerateMnemonic(language: ViewController.KeypairLanguage,
                                                       words: ViewController.KeypairWords,
                                                       mnem:&mnem)
      if(ret < 0) {
        showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GenerateMnemonic()")
        return
      }
      _ = newAndSaveMnemonic(mnem)
    }

    showMessage("Mnemonic:\(mSavedMnemonic ?? "nil")\n")
    
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    mPeerNode = PeerNode.GetInstance(path: cacheDir!.path, deviceId: getDeviceId())
    
    mPeerNodeListener = {
      class Impl: PeerNodeListener.Listener {
        init(_ vc: ViewController) {
          viewCtrl = vc
          super.init()
        }

        override func onAcquire(request: Contact.Listener.AcquireArgs) -> Data? {
          let ret = viewCtrl.processAcquire(request: request)

          var msg = "onAcquire(): req=\(request.toString())\n"
          msg += "onAcquire(): resp=\(String(describing: ret))\n"
          viewCtrl.showEvent(msg)

          return ret
        }

        override func onError(errCode: Int, errStr: String, ext: String?) {
          var msg = "\(errCode): \(errStr)"
          msg += "\n\(String(describing: ext))"
          viewCtrl.showError(msg)
        }

        private let viewCtrl: ViewController
      }

      return Impl(self)
    }()
    mPeerNode!.setListener(listener: mPeerNodeListener!)
    let ret = mPeerNode!.start()
    if(ret < 0) {
      showError("Failed to start PeerNode. ret = \(ret)")
    }
    showMessage("Success to start PeerNode.")
  }
  
  private func createConnector() {
    if (mConnector != nil) {
      return;
    }
    
    mConnector = Connector(serviceName: "Test")
    mMsgListener = {
      class Impl: PeerNodeListener.MessageListener {
        init(_ vc: ViewController) {
          viewCtrl = vc
          super.init()
        }

        override func onEvent(event: Contact.Listener.EventArgs) {
          viewCtrl.processEvent(event: event)
        }

        override func onReceivedMessage(humanCode: String,
                                        channelType: Contact.Channel,
                                        message: Contact.Message) {
          var msg = "onRcvdMsg(): from=\(humanCode)\n"
          msg += "onRcvdMsg(): data=\(message.data.toString())\n"
          msg += "onRcvdMsg(): type=\(message.type)\n"
          msg += "onRcvdMsg(): crypto=" + (message.cryptoAlgorithm ?? "nil") + "\n"
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
        let msgInfo = Contact.MakeTextMessage(text: message!, cryptoAlgorithm: nil)

        let status = self.mConnector!.getFriendStatus(friendCode: friendCode!)
        if(status != Contact.Status.Online) {
          self.showMessage(ViewController.ErrorPrefix + "Friend is not online.")
          return
        }

        let ret = self.mConnector!.sendMessage(friendCode: friendCode!,
                                               message: msgInfo)
        if(ret < 0) {
          self.showMessage(ViewController.ErrorPrefix + "Failed to send message to " + friendCode!)
        }
      })
    })

  }

  
  @IBAction func onOptionsMenuTapped(_ sender: Any) {
    optionsMenu.isHidden = !optionsMenu.isHidden
  }
  
  @IBAction func onOptionsItemSelected(_ sender: UIButton) {
    optionsMenu.isHidden = true

    enum ButtonTag: Int {
      case create_service = 100
      case send_msg = 101
    }
    
    switch sender.tag {
    case ButtonTag.create_service.rawValue:
      createConnector()
      break
    case ButtonTag.send_msg.rawValue:
      sendMessage()
      break
    default:
      fatalError("Button [\(sender.currentTitle!)(\(sender.tag))] not decleared.")
    }
  }

func newAndSaveMnemonic(_ newMnemonic: String?) -> String? {
    mSavedMnemonic = newMnemonic
    if mSavedMnemonic == nil {
      var mnem = String()
      let ret = Contact.Debug.Keypair.GenerateMnemonic(language: ViewController.KeypairLanguage,
                                                       words: ViewController.KeypairWords,
                                                       mnem:&mnem)
      if(ret < 0) {
        showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GenerateMnemonic()")
        return nil
      }
      mSavedMnemonic = mnem
    }
  
    UserDefaults.standard.set(mSavedMnemonic, forKey: ViewController.SavedMnemonicKey)

    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.message = "New mnemonic can only be valid after restart,\ndo you want restart app?"
    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
      exit(0)
    }))
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
    self.present(dialog, animated: false, completion: nil)

    return ("Cancel to save mnemonic: \(newMnemonic ?? "nil")\n")
  }
  
  private func processAcquire(request: Contact.Listener.AcquireArgs) -> Data? {
    var response: Data?
  
    switch (request.type) {
      case .PublicKey:
        response = getPublicKey().data(using: .utf8)
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
  
  private func getPublicKey() -> String {
    var seed = Data()
    var ret = Contact.Debug.Keypair.GetSeedFromMnemonic(mnemonic: mSavedMnemonic!,
                                                        mnemonicPassword: "",
                                                        seed: &seed)
    if(ret < 0) {
      showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GetSeedFromMnemonic()")
    }
    var pubKey = String()
    ret = Contact.Debug.Keypair.GetSinglePublicKey(seed: seed, pubKey: &pubKey)
    if(ret < 0) {
      showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GetSinglePublicKey()")
    }

    return pubKey
  }

  private func getPrivateKey() -> String {
    var seed = Data()
    var ret = Contact.Debug.Keypair.GetSeedFromMnemonic(mnemonic: mSavedMnemonic!,
                                                        mnemonicPassword: "",
                                                        seed: &seed)
    if(ret < 0) {
      showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GetSeedFromMnemonic()")
    }
    var privKey = String()
    ret = Contact.Debug.Keypair.GetSinglePrivateKey(seed: seed, privKey: &privKey)
    if(ret < 0) {
      showMessage(ViewController.ErrorPrefix + "Failed to call Contact.Debug.Keypair.GetSinglePrivateKey()")
    }

    return privKey
  }
  
  private func getAgentAuthHeader() -> Data {
    let appid = "org.elastos.debug.didplugin"
    //let appkey = "b2gvzUM79yLhCbbGNWCuhSsGdqYhA7sS"
    let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    let auth = Utils.getMD5Sum(str: "appkey\(timestamp)")
    let headerValue = "id=\(appid)time=\(timestamp)auth=\(auth)"
    Log.i(tag: ViewController.TAG, msg: "getAgentAuthHeader() headerValue=" + headerValue)
  
    return headerValue.data(using: .utf8)!
  }
  
  private func signData(data: Data?) -> Data? {
    if data == nil {
      return nil
    }
    
    let privKey = getPrivateKey()

    var signedData = Data()
    let ret = Contact.Debug.Keypair.Sign(privateKey: privKey, data: data!, signedData: &signedData)
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
  
  private func showMessage(_ msg: String) {
    Log.i(tag: ViewController.TAG, msg: "\(msg)")
    
    DispatchQueue.main.async { [weak self] in
      self?.msgLog.text = msg
    }
    
    if msg.hasPrefix(ViewController.ErrorPrefix) {
      showToast(msg)
    }
  }
  
  private func showEvent(_ newMsg: String) {
    print("\(newMsg)")
    DispatchQueue.main.async { [weak self] in
      self?.eventLog.text += "\n"
      self?.eventLog.text += newMsg
    }
  }
  
  private func showError(_ newErr: String) {
    Log.e(tag: ViewController.TAG, msg: newErr)

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
  private var mSavedMnemonic: String?
  private var mPeerNode: PeerNode?
  private var mPeerNodeListener: PeerNodeListener.Listener?
//  private var mContactDataListener: Contact.DataListener?
//
  private var mConnector: Connector?
  private var mMsgListener: PeerNodeListener.MessageListener?

  
//  private var mContactRecvFileMap = [String: Contact.Message.FileData]()
//  private var mContactSendFileMap = [String: String]()
//
  private static let KeypairLanguage = "english"
  private static let KeypairWords = ""
  private static let SavedMnemonicKey = "mnemonic"
  private static let ErrorPrefix = "Error: "
  private static let TAG = "ContactTest"

}

