import UIKit

public class Helper {
  public typealias OnListener = (_ result: String?) -> Void
  public typealias OnPhotoSelectListener = (_ image: UIImage, _ url: URL) -> Void
  public typealias OrderedDictionary =  [(key: String, value: String?)]

  public static func showImportMnemonic(view: UIViewController, listener: @escaping OnListener) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "Import Mnemonic"
    
    let rootView = UITextView()
    setDialogContent(dialog, 200, rootView)

    dialog.addAction(UIAlertAction(title: "Import", style: .default, handler: { _ in
      listener(rootView.text)
    }))
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    showDialog(view, dialog)
  }

  public static func showAddress(view: UIViewController,
                                 listener: @escaping OnListener,
                                 humanCode: OrderedDictionary, presentDevId: String, ext: String?) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "My Address"
    
    let rootView = makeAddressView(view: view, width: dialog.view.widthAnchor, listener: listener,
                                   humanCode: humanCode, presentDevId: presentDevId, ext: ext)
    setDialogContent(dialog, -1, rootView)

    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    showDialog(view, dialog);
    
//        AlertDialog.Builder builder = new AlertDialog.Builder(context);
//        builder.setTitle("My Address");
//        try {
//            View root = makeAddressView(context, humanCode, presentDevId, ext, listener);
//            builder.setView(root);
//        } catch (Exception e) {
//            String msg = "Failed to show address.";
//            builder.setMessage(msg + e);
//            Log.w(TAG, msg, e);
//        }
//
//        builder.setNegativeButton("Cancel", (dialog, which) -> {
//            dismissDialog();
//        });
//
//        showDialog(builder);
    }
//
    public static func showSetDetails(view: UIViewController,
                                      checkList: [String], separator: String,
                                      listener: @escaping OnListener) {
      let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
      dialog.title = "Set Details"
      
      
      let radioGrp = RadioGroupView()
      let editView =  UITextView()
      
      radioGrp.addRadioButtons(titles: checkList, selected: 0)
      let rootView = makeSetDetailView(view: view, radioGrp: radioGrp, editView: editView);
      setDialogContent(dialog, 300, rootView)
    
      dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        let key = radioGrp.selectedTitle!
        let value = editView.text
      
        listener(key + separator + (value ?? ""))
      }))
      dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))

      showDialog(view, dialog);
    }

  public static func showDetails(view: UIViewController, msg: String) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

    dialog.title = "Details"
    let rootView = UITextView()
    rootView.text = msg
    rootView.isEditable = false
    setDialogContent(dialog, -1, rootView)
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      
    showDialog(view, dialog);
  }

  public static func showFriendList(view: UIViewController, friendList: [String],
                                    listener: @escaping OnListener) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "Friend List"

    let impl: NSObject = {
      class Impl : NSObject, UITableViewDataSource, UITableViewDelegate {
        init(_ friendList: [String], _ listener: @escaping OnListener) {
          self.friendList = friendList
          self.listener = listener
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return friendList.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
          let friendCode = friendList[indexPath.item]
          let valPrefix = friendCode[..<friendCode.index(friendCode.startIndex, offsetBy: 5)]
          let valSuffix = friendCode[friendCode.index(friendCode.endIndex, offsetBy: -10)...]
          let label = "" + valPrefix + " ... " + valSuffix
          cell.textLabel?.text = label
          
          return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          let friendCode = friendList[indexPath.item]
          listener(friendCode)
        }
        
        private let friendList: [String]
        private let listener: OnListener
      }
      
      return Impl(friendList, listener)
    }()
    _ = Unmanaged.passRetained(impl)

    let listView = UITableView()
    listView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    listView.delegate = (impl as! UITableViewDelegate)
    listView.dataSource = (impl as! UITableViewDataSource)

    setDialogContent(dialog, 500, listView)
    
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      _ = Unmanaged.passRetained(impl).autorelease()
    }))

    showDialog(view, dialog, release: impl)
  }

  public static func showAddFriend(view: UIViewController, friendCode: String,
                                   listener: @escaping OnListener) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "Found Address"

    let edit = UITextView()
    let rootView = makeEditView(view, friendCode, edit)
    setDialogContent(dialog, 300, rootView)
      
    dialog.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
      listener(edit.text)
    }))
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    showDialog(view, dialog)
  }

  public static func showFriendRequest(view: UIViewController,
                                       humanCode: String, summary: String,
                                       listener: @escaping OnListener) {
    DispatchQueue.main.async {
      let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
      dialog.title = "Friend Request"

      var msg = "FriendCode:\n  " + humanCode + "\n\n"
      msg += "Summary:\n  " + summary
      
      let rootView = UITextView()
      rootView.text = msg
      rootView.isEditable = false
      setDialogContent(dialog, 500, rootView)
      
      dialog.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
        listener(nil)
      }))
      dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))

      showDialog(view, dialog)
    }
  }

  public static func showTextSendMessage(view: UIViewController,
                                         friendCode: String,
                                         listener: @escaping OnListener) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "Send Text Message"

    let edit = UITextView()
    let rootView = makeEditView(view, friendCode, edit)
    setDialogContent(dialog, 500, rootView)
      
    dialog.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
      listener(edit.text)
    }))
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    showDialog(view, dialog)
  }
  
  public static func showFileSendMessage(view: UIViewController,
                                         friendCode: String,
                                         listener: @escaping OnListener) {
    let dialog = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    dialog.title = "Send File Message"

    let edit = UITextView()
    let rootView = makeFileChoiceView(view, friendCode, edit)
    setDialogContent(dialog, 500, rootView)
      
    dialog.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
      listener(edit.text)
    }))
    dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    showDialog(view, dialog)
  }

  public static func scanAddress(view: UIViewController, listener: @escaping OnListener) {
    selectPhoto(view: view, listener: { image, _ in
      let result = Helper.makeQRCodeString(value: image)
      listener(result)
    })
  }

//    public static void onRequestPermissionsResult(MainActivity activity, int requestCode, String[] permissions, int[] grantResults) {
//        if (requestCode != 1) {
//            return;
//        }
//
//        for (int idx = 0; idx < permissions.length; idx++) {
//            if(permissions[idx].equals(Manifest.permission.CAMERA) == false) {
//                continue;
//            }
//
//            if (grantResults[idx] == PackageManager.PERMISSION_GRANTED) {
//                Intent intent = new Intent(activity, QrCodeActivity.class);
//                activity.startActivityForResult(intent, REQUEST_CODE_QR_SCAN);
//            }
//        }
//    }
//
//    public static void onActivityResult(MainActivity activity, int requestCode, int resultCode, Intent data) {
//        if(resultCode != Activity.RESULT_OK) {
//            Log.d(TAG,"COULD NOT GET A GOOD RESULT.");
//            if(data == null) {
//                return;
//            }
//            String result = data.getStringExtra("com.blikoon.qrcodescanner.error_decoding_image");
//            if(result == null) {
//                return;
//            }
//
//            activity.showMessage("QR Code could not be scanned.");
//        }
//
//        if(requestCode == REQUEST_CODE_QR_SCAN) {
//            if(data==null)
//                return;
//            //Getting the passed result
//            String result = data.getStringExtra("com.blikoon.qrcodescanner.got_qr_scan_relult");
//            Log.d(TAG,"Scan result:"+ result);
//
//            mOnScanListener.onResult(result);
//            mOnScanListener = null;
//        }
//    }
//
  private static func makeAddressView(view: UIViewController, width: NSLayoutDimension,
                                      listener: @escaping OnListener,
                                      humanCode: OrderedDictionary, presentDevId: String?, ext: String?) -> UIView {
    let txtDevId = UITextView()
    let imgQRCode = UIImageView()
    let radioGrp = RadioGroupView()
    let txtCode =  UITextView()
    let btn =  UIButton()

    txtDevId.isEditable = false
    txtDevId.text = "Present DevId: " + (presentDevId ?? "nil")
    txtCode.isEditable = false
    
    radioGrp.axis = .vertical
    radioGrp.setOnClickedClosure(closure: { (index, button) in
      let checkedVal = Array(humanCode)[index].value
      var showed = checkedVal
      if(index == humanCode.count - 1) {
        showed! += "\n----------------\n" + ext!;
      }
      
      let bitmap = makeQRCodeImage(value: checkedVal!)
      imgQRCode.image = bitmap
      txtCode.text = showed
    })
    for idx in humanCode.indices {
      let key = humanCode[idx].key
      let value = humanCode[idx].value!
      let valPrefix = value[..<value.index(value.startIndex, offsetBy: 5)]
      let valSuffix = value[value.index(value.endIndex, offsetBy: -5)...]
      let label = key + ": " + valPrefix + " ... " + valSuffix
      
      radioGrp.addRadioButton(title: label, selected: idx == humanCode.startIndex)
    }
    
    btn.setTitle("Details", for: .normal)
    btn.setTitleColor(.blue, for: .normal)
    btn.addTargetClosure(closure: { sender in
      listener(nil)
    })
    
    let rootView = UIStackView()
    rootView.axis = .vertical
    rootView.addArrangedSubview(txtDevId)
    rootView.addArrangedSubview(imgQRCode)
    rootView.addArrangedSubview(txtCode);
    rootView.addArrangedSubview(radioGrp)
    rootView.addArrangedSubview(btn)

    txtDevId.translatesAutoresizingMaskIntoConstraints = false
    txtDevId.heightAnchor.constraint(equalToConstant: 50).isActive = true
    imgQRCode.translatesAutoresizingMaskIntoConstraints = false
    imgQRCode.heightAnchor.constraint(equalTo: imgQRCode.widthAnchor).isActive = true
    txtCode.translatesAutoresizingMaskIntoConstraints = false
    txtCode.heightAnchor.constraint(equalToConstant: 100).isActive = true
    radioGrp.translatesAutoresizingMaskIntoConstraints = false
    radioGrp.widthAnchor.constraint(equalToConstant: 150).isActive = true
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.heightAnchor.constraint(equalToConstant: 50).isActive = true

    return rootView
  }

  private static func makeSetDetailView(view: UIViewController,
                                        radioGrp: RadioGroupView,
                                        editView: UITextView) -> UIView {
    let txtView = UITextField()

    let rootView = UIStackView()
    rootView.axis = .vertical
    
    rootView.addArrangedSubview(radioGrp)
    rootView.addArrangedSubview(txtView)
    rootView.addArrangedSubview(editView)

    radioGrp.axis = .vertical
   
    txtView.text = "Value:"
    editView.text = "TestUser"

    return rootView
  }

  private static func makeEditView(_ view: UIViewController,
                                   _ friendCode: String, _ edit: UITextView) -> UIView {
    let txtCode = UITextView()
    let txtMsg = UILabel()
    
    let root = UIStackView()
    root.axis = .vertical
    root.addArrangedSubview(txtCode)
    root.addArrangedSubview(txtMsg)
    root.addArrangedSubview(edit)

    txtCode.isEditable = false
    txtCode.translatesAutoresizingMaskIntoConstraints = false
    txtCode.heightAnchor.constraint(equalToConstant: 40).isActive = true

    txtCode.text = "FriendCode:\n  " + friendCode
    txtMsg.text = "Message:"
    edit.text = "Hello"

    return root;
  }
  
  private static func makeFileChoiceView(_ view: UIViewController,
                                         _ friendCode: String, _ txtFileName: UITextView) -> UIView {
    let txtCode = UITextView()
    let txtMsg = UILabel()
    
    let btnSel =  UIButton()
    btnSel.setTitle("Select", for: .normal)
    btnSel.setTitleColor(.blue, for: .normal)
    btnSel.addTargetClosure(closure: { sender in
      let dialog = mLastDialog!
      dismissDialog()
      selectPhoto(view: view, listener: { _, url in
        showDialog(view, dialog)
        txtFileName.text = url.path
      })
    })

    let root = UIStackView()
    root.axis = .vertical
    root.addArrangedSubview(txtCode)
    root.addArrangedSubview(txtMsg)
    root.addArrangedSubview(txtFileName)
    root.addArrangedSubview(btnSel)

    txtCode.isEditable = false
    txtCode.translatesAutoresizingMaskIntoConstraints = false
    txtCode.heightAnchor.constraint(equalToConstant: 40).isActive = true

    txtCode.text = "FriendCode:\n  " + friendCode
    txtMsg.text = "File:"
    
    txtFileName.isEditable = false

    return root;
  }

  private static func selectPhoto(view: UIViewController, listener: @escaping OnPhotoSelectListener) {
    let imagePicker = ImagePicker()
    
    let impl: NSObject = {
      class Impl : NSObject, ImagePickerDelegate {
        init(_ imagePicker: ImagePicker, _ viewCtrl: UIViewController, _ listener: @escaping OnPhotoSelectListener) {
          self.imagePicker = imagePicker
          self.viewCtrl = viewCtrl
          self.listener = listener
        }
        
        func imagePickerDelegate(didSelect image: UIImage, didSelectUrl imageUrl: URL,
                                 delegatedForm: ImagePicker) {
          listener(image, imageUrl)
          delegatedForm.dismiss()
          _ = Unmanaged.passRetained(self).autorelease()
        }

        func imagePickerDelegate(didCancel delegatedForm: ImagePicker) {
          delegatedForm.dismiss()
          _ = Unmanaged.passRetained(self).autorelease()
        }

        func imagePickerDelegate(canUseGallery accessIsAllowed: Bool, delegatedForm: ImagePicker) {
          if accessIsAllowed {
            delegatedForm.present(parent: viewCtrl, sourceType: .photoLibrary)
          }
        }

        func imagePickerDelegate(canUseCamera accessIsAllowed: Bool, delegatedForm: ImagePicker) {
            // works only on real device (crash on simulator)
          if accessIsAllowed {
            delegatedForm.present(parent: viewCtrl, sourceType: .camera)
           }
        }

        private let imagePicker: ImagePicker
        private let viewCtrl: UIViewController
        private let listener: OnPhotoSelectListener
       }
       
       return Impl(imagePicker, view, listener)
     }()
     _ = Unmanaged.passRetained(impl)

    imagePicker.delegate = (impl as? ImagePickerDelegate)
    imagePicker.photoGalleryAsscessRequest()
  }


  
  private static func makeQRCodeImage(value: String) -> UIImage? {
    let data = value.data(using: String.Encoding.ascii)

    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(data, forKey: "inputMessage")
    let transform = CGAffineTransform(scaleX: 3, y: 3)

    guard let output = (filter!.outputImage?.transformed(by: transform)) else {
      return nil
    }
    
    let ret = UIImage(ciImage: output)
    return ret
  }
  
  private static func makeQRCodeString(value: UIImage) -> String? {
    guard let image = CIImage(image: value) else {
        return nil
    }

    let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                              context: nil,
                              options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    let features = detector?.features(in: image) ?? []

    let ret = features.compactMap { feature in
        return (feature as? CIQRCodeFeature)?.messageString
    }
    
    return (ret.count > 0 ? ret[0] : nil)
  }

  private static func setDialogContent(_ dialog: UIAlertController, _ height: CGFloat, _ contentView: UIView) {
    dialog.view.translatesAutoresizingMaskIntoConstraints = false
    dialog.view.heightAnchor.constraint(equalToConstant: height >= 0.0 ? height : 10000).isActive = true

    dialog.view.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.leftAnchor.constraint(equalTo: dialog.view.leftAnchor, constant: 10).isActive = true
    contentView.rightAnchor.constraint(equalTo: dialog.view.rightAnchor, constant: -10).isActive = true
    contentView.topAnchor.constraint(equalTo: dialog.view.topAnchor, constant: 45).isActive = true
    contentView.bottomAnchor.constraint(equalTo: dialog.view.bottomAnchor, constant: -45).isActive = true
  }
  
  public static func showDialog(_ view: UIViewController, _ dialog: UIAlertController, release: NSObject? = nil) {
    dismissDialog(release)

    DispatchQueue.main.async {
      mLastDialog = dialog
      view.present(mLastDialog!, animated: false)
    }
  }

  public static func dismissDialog(_ release: NSObject? = nil) {
    guard mLastDialog != nil else { return }

    DispatchQueue.main.async {
      mLastDialog!.dismiss(animated: false)
      mLastDialog = nil
    }

    if release != nil {
      _ = Unmanaged.passRetained(release!).autorelease()
    }
  }

  private static var mLastDialog: UIAlertController? = nil
//  private static var mTableViewDelegate: NSObject? = nil
//    private static OnListener mOnScanListener;
//    private static final int REQUEST_CODE_QR_SCAN = 101;
}

