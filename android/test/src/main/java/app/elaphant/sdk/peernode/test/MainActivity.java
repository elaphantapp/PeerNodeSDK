package app.elaphant.sdk.peernode.test;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.AlertDialog;
import android.app.PendingIntent;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.preference.PreferenceManager;
import android.provider.Settings;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;
import android.widget.Toast;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.elastos.sdk.keypair.ElastosKeypair;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;

import com.google.gson.Gson;

public class MainActivity extends Activity {
    public static final String TAG = "ContactTest";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        TextView txtError = findViewById(R.id.txt_error);
        txtError.setMovementMethod(ScrollingMovementMethod.getInstance());
        TextView txtCbMsg = findViewById(R.id.txt_event);
        txtCbMsg.setMovementMethod(ScrollingMovementMethod.getInstance());
        TextView txtMsg = findViewById(R.id.txt_message);
        txtMsg.setMovementMethod(ScrollingMovementMethod.getInstance());
        txtMsg.setOnLongClickListener((v) -> {
            setClip(((TextView)v).getText().toString());
            return true;
        });

        Contact.Factory.SetLogLevel(7);

//        String devId = getDeviceId();
//        Log.i(TAG, "Device ID:" + devId);
//
//        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
//        mSavedMnemonic = pref.getString(SavedMnemonicKey, null);
//        if(mSavedMnemonic == null) {
//            mSavedMnemonic = ElastosKeypair.generateMnemonic(KeypairLanguage, KeypairWords);
////            if (devId.startsWith("7134d")) {
////                mSavedMnemonic = UploadedMnemonic1;
////            }
//            if (devId.startsWith("fa65a")) {
//                mSavedMnemonic = UploadedMnemonic1;
//            }
////            mSavedMnemonic = UploadedMnemonic1;
//
//            newAndSaveMnemonic(mSavedMnemonic);
//        }
//
//        showMessage("Mnemonic:\n" + mSavedMnemonic);

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        Process.killProcess(Process.myPid());
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        String message = "";

//        int id = item.getItemId();
//        switch (id) {
//            case R.id.get_started:
//                getStarted();
//                break;
//
//            case R.id.clear_event: {
//                clearEvent();
//                break;
//            }
//
//            case R.id.new_mnemonic:
//                message = newAndSaveMnemonic(null);
//                break;
////            case R.id.save_mnemonic: {
////                saveMnemonic(mSavedMnemonic);
////                message = ("Success to save mnemonic:\n" + mSavedMnemonic);
////                break;
////            }
//            case R.id.import_mnemonic:
//                message = importMnemonic();
//                break;
//
//            case R.id.new_and_start_contact:
//                message = testNewContact();
//                message += testStartContact();
//                break;
//            case R.id.stop_and_del_contact:
//                message = testStopContact();
//                message += testDelContact();
//                break;
//            case R.id.recreate_contact:
//                message = testStopContact();
//                message += testDelContact();
//                message += testNewContact();
//                message += testStartContact();
//                break;
//            case R.id.restart_contact:
//                message = testStopContact();
//                message += testStartContact();
//                break;
//
//            case R.id.get_user_info:
//                message = showGetUserInfo();
//                break;
//            case R.id.set_user_identifycode:
//                message = showSetUserIdentifyCode();
//                break;
//            case R.id.set_user_details:
//                message = showSetUserDetails();
//                break;
//            case R.id.set_wallet_address:
//                message = showSetWalletAddress();
//                break;
//            case R.id.sync_upload:
//                message = testSyncUpload();
//                break;
//            case R.id.sync_download:
//                message = testSyncDownload();
//                break;
//
//            case R.id.friend_info:
//                message = listFriendInfo();
//                break;
//            case R.id.add_friend:
//                message = scanUserInfo();
//                break;
//            case R.id.del_friend:
//                message = removeFriend();
//                break;
//            case R.id.set_friend_details:
//                message = showSetFriendDetails();
//                break;
//            case R.id.send_text_message:
//                message = sendTextMessage();
//                break;
//            case R.id.send_binary_message:
//                message = sendBinaryMessage();
//                break;
//            case R.id.send_file_message:
//                message = sendFileMessage();
//                break;
//            case R.id.pull_file:
//                message = pullFile();
//                break;
//            case R.id.cancel_pull_file:
//                message = cancelPullFile();
//                break;
//
//            case R.id.show_cached_didprop:
//                message = getCachedDidProp();
//                break;
//        }
//        showMessage(message);

        return super.onOptionsItemSelected(item);
    }

    private void clearEvent() {
        TextView txtCbMsg = findViewById(R.id.txt_event);
        txtCbMsg.setText("");
        txtCbMsg.invalidate();
    }

    private void getStarted() {
        String help = "";
        help += "Step1: [New Contact]\n";
        help += "Step2: [Start Contact]\n";
        help += "Step3: [User Info] can show you info\n";
        help += "Step4: After online, [Add friend] can add friend\n";
        help += "Step5: After friend online, [Send Message] can send message\n";

        clearEvent();
//        showEvent(help);
    }

//    private String importMnemonic() {
//        Helper.showImportMnemonic(this, (result) -> {
//            if(isEnglishWords(result) == false) {
//                showMessage(ErrorPrefix + "Only english mnemonic is supported.");
//                return;
//            }
//            String privKey = getPrivateKey();
//            if(privKey == null || privKey.isEmpty()) {
//                showMessage(ErrorPrefix + "Bad mnemonic.");
//                return;
//            }
//
//            String message = newAndSaveMnemonic(result);
//            showMessage(message);
//        });
//
//        return "Success to show import mnemonic dialog.";
//    }
//
//    private String testNewContact() {
//        if(mContact != null) {
//            return ErrorPrefix + "Contact is created.";
//        }
//
//        Contact.Factory.SetLogLevel(7);
//
//        Contact.Factory.SetDeviceId(getDeviceId());
//
//        int ret = Contact.Factory.SetLocalDataDir(this.getCacheDir().getAbsolutePath());
//        if(ret < 0) {
//            return "Failed to call Contact.Factory.SetLocalDataDir() ret=" + ret;
//        }
//
//        mContact = Contact.Factory.Create();
//        if(mContact == null) {
//            return "Failed to call Contact.Factory.Create()";
//        }
//
//        if(mContactListener != null) {
//            mContactListener = null;
//        }
//        mContactListener = new Contact.Listener() {
//            @Override
//            public byte[] onAcquire(AcquireArgs request) {
//                byte[] ret = processAcquire(request);
//
//                String msg = "onAcquire(): req=" + request + "\n";
//                msg += "onAcquire(): resp=" + ret + "\n";
//                showEvent(msg);
//
//                return ret;
//            }
//
//            @Override
//            public void onEvent(EventArgs event) {
//                processEvent(event);
//
//                String msg = "onEvent(): ev=" + event + "\n";
//                showEvent(msg);
//            }
//
//            @Override
//            public void onReceivedMessage(String humanCode, ContactChannel channelType, Contact.Message message) {
//                String msg = "onRcvdMsg(): data=" + message.data + "\n";
//                msg += "onRcvdMsg(): type=" + message.type + "\n";
//                msg += "onRcvdMsg(): crypto=" + message.cryptoAlgorithm + "\n";
//                showEvent(msg);
//
//                if(message.type == Contact.Message.Type.MsgFile) {
//                    mContactRecvFileMap.put(humanCode, (Contact.Message.FileData)message.data);
//                }
//            }
//
//            @Override
//            public void onError(int errCode, String errStr, String ext) {
//                String msg = errCode + ": " + errStr;
//                msg += "\n" + ext;
//                showError(msg);
//            }
//        };
//        mContact.setListener(mContactListener);
//
//        mContactDataListener = new Contact.DataListener() {
//            @Override
//            public void onNotify(String humanCode, ContactChannel channelType,
//                                 String dataId, Status status)
//            {
//                String msg = "onNotify(): dataId=" + dataId + ", status=" + status + "\n";
//                showEvent(msg);
//            }
//
//            @Override
//            public int onReadData(String humanCode, ContactChannel channelType,
//                                  String dataId, long offset, ByteBuffer data)
//            {
//                String filepath = mContactSendFileMap.get(dataId);
//                if(filepath == null) {
//                    return -1;
//                }
//
//                File file = new File(filepath);
//                if(file.exists() == false) {
//                    return -1;
//                }
//                String msg = "onReadData(): dataId=" + dataId + ", offset=" + offset + "\n";
//                if(offset == 0 || offset >= file.length()) {
//                    showEvent(msg);
//                } else {
//                    Log.v(TAG, msg);
//                }
//
//
//                if(offset >= file.length()) {
//                    return 0;
//                }
//
//
//                FileInputStream fis = null;
//                try {
//                    fis = new FileInputStream(file);
//                    fis.skip(offset);
//                    int num = fis.read(data.array());
//                    return num;
//                } catch (Exception e) {
//                    return -1;
//                } finally {
//                    try {
//                        if(fis != null) fis.close();
//                    } catch (IOException e) {
//                    }
//                }
//            }
//
//            @Override
//            public int onWriteData(String humanCode, ContactChannel channelType,
//                                   String dataId, long offset, byte[] data)
//            {
//                String msg = "onWriteData(): dataId=" + dataId + ", offset=" + offset + "\n";
//                if(offset == 0 || data.length == 0) {
//                    showEvent(msg);
//                } else {
//                    Log.v(TAG, msg);
//                }
//
//                ContactMessage.FileData fileInfo = new Gson().fromJson(dataId, ContactMessage.FileData.class);
//
//                File file = new File(MainActivity.this.getCacheDir(), fileInfo.name);
//                if(data.length == 0) {
//                    String md5 = Utils.getMD5Sum(file);
//                    if(md5 != null && md5.equals(fileInfo.md5))  {
//                        msg = "onWriteData(): Success to pull dataId=" + dataId + "\n";
//                    } else {
//                        msg = "onWriteData(): Failed to pull dataId=" + dataId + "\n";
//                    }
//                    showEvent(msg);
//
//                    return 0;
//                }
//
//                FileOutputStream fos = null;
//                try {
//                    fos = new FileOutputStream(file, offset == 0 ? false:true);
//                    fos.write(data);
//                    fos.flush();
//                    Log.d(TAG, "file size=" + file.length());
//                    return data.length;
//                } catch (Exception e) {
//                    return -1;
//                } finally {
//                    try {
//                        if(fos != null) fos.close();
//                    } catch (IOException e) {
//                    }
//                }
//            }
//        };
//        mContact.setDataListener(mContactDataListener);
//
//        return "Success to create a contact instance.";
//    }
//
//    private String testStartContact() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
////        mThread = new Thread(() -> {
//            int ret = mContact.start();
////        });
////        mThread.start();
//        if(ret < 0) {
//            return "Failed to start contact instance. ret=" + ret;
//        }
//
////        String recvKey;
////        String recvDataId;
////        String sendDataId;
////        String sendFilePath;
////        if(mContact.getUserInfo().humanCode.equals("igh7qBS5BYLLG9PqfF6gY1ytjnwvAKRcEx")) {
////            recvKey = "iZJo8cTTffSgC5bzKqjLisgK3yWtJnqkHv";
////            recvDataId = "{\"DevId\":\"fa65acd8af43ae7\",\"Md5\":\"c9192c39e36b4d038b3dcea09dda0d1b\",\"Name\":\"Picture_02_Imagination.jpg\",\"Size\":639234}";
////            sendDataId = "{\"DevId\":\"9fdb3e667aec0e60\",\"Md5\":\"de57b4c20b3d7cffed47ba42d1f0f0ad\",\"Name\":\"P91025-131156.jpg\",\"Size\":3217685}";
////            sendFilePath = "/storage/emulated/0/DCIM/P91025-131156.jpg";
////        } else {
////            recvKey = "igh7qBS5BYLLG9PqfF6gY1ytjnwvAKRcEx";
////            recvDataId = "{\"DevId\":\"9fdb3e667aec0e60\",\"Md5\":\"de57b4c20b3d7cffed47ba42d1f0f0ad\",\"Name\":\"P91025-131156.jpg\",\"Size\":3217685}";
////            sendDataId = "{\"DevId\":\"fa65acd8af43ae7\",\"Md5\":\"c9192c39e36b4d038b3dcea09dda0d1b\",\"Name\":\"Picture_02_Imagination.jpg\",\"Size\":639234}";
////            sendFilePath = "/system/media/Pre-loaded/Pictures/Picture_02_Imagination.jpg";
////        }
////
////        Contact.Message fileMsg = new Contact.Message(Contact.Message.Type.MsgFile,
////                recvDataId.getBytes(), null);
////        mContactRecvFileMap.put(recvKey, (Contact.Message.FileData)fileMsg.data);
////        mContactSendFileMap.put(sendDataId, sendFilePath);
////
////        recvKey = "ii9ab8jGVRg5GKfZsGe4NYHupFd2Y7xUif";
////        recvDataId = "{\"DevId\":\"AC200C58-6375-48E8-85D7-E27255D94C41\",\"Md5\":\"6345517ead2f2776f680ec598e4df559\",\"Name\":\"3CDA6326-1CDB-47E7-A055-763589AFBFEA.jpeg\",\"Size\":1896240}";
////        fileMsg = new Contact.Message(Contact.Message.Type.MsgFile, recvDataId.getBytes(), null);
////        mContactRecvFileMap.put(recvKey, (Contact.Message.FileData)fileMsg.data);
//
//        return "Success to start contact instance.";
//    }
//
//    private String testStopContact() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        int ret = mContact.stop();
//        if(ret < 0) {
//            return "Failed to stop contact instance. ret=" + ret;
//        }
//
//        return "Success to stop contact instance.";
//    }
//
//    private String testDelContact() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        mContact = null;
//        System.gc(); // to test memory release
//        return "Success to delete a contact instance.";
//    }
//
//    private String showGetUserInfo() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        LinkedHashMap<String, String> humanCode = new LinkedHashMap<String, String>() {{
//            put("Did", info.did);
//            put("Ela", info.elaAddress);
//            put("Carrier", info.getCurrDevCarrierAddr());
//        }};
//        String ext = info.getCurrDevCarrierId();
//        Helper.showAddress(this, humanCode, getDeviceId(), ext, (result) -> {
//            Helper.showDetails(MainActivity.this, info.toJson());
//        });
//
//        return info.toString();
//    }
//
//    private String showSetUserIdentifyCode() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        LinkedList<String> checkList = new LinkedList<>(Arrays.asList(
//                Contact.UserInfo.Type.PhoneNumber.name(),
//                Contact.UserInfo.Type.EmailAddress.name(),
//                Contact.UserInfo.Type.WechatId.name()
//        ));
//        String separator = ":-:-:";
//
//        Helper.showSetDetails(this, checkList, separator, (result) -> {
//            HashMap<String, Contact.UserInfo.Type> details = new HashMap<String, Contact.UserInfo.Type>() {{
//                put(Contact.UserInfo.Type.PhoneNumber.name(), Contact.UserInfo.Type.PhoneNumber);
//                put(Contact.UserInfo.Type.EmailAddress.name(), Contact.UserInfo.Type.EmailAddress);
//                put(Contact.UserInfo.Type.WechatId.name(), Contact.UserInfo.Type.WechatId);
//            }};
//
//            String[] keyValue = result.split(separator);
//            Contact.UserInfo.Type type = details.get(keyValue[0]);
//            String value = keyValue[1];
//
//            int ret = mContact.setIdentifyCode(type, value);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to set " + result + ". ret=" + ret);
//            }
//        });
//
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        return info.toString();
//    }
//
//    private String showSetUserDetails() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        setHumanDetails(info.humanCode);
//
//        info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        return info.toString();
//    }
//
//    private String setHumanDetails(String humanCode) {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        LinkedList<String> checkList = new LinkedList<>(Arrays.asList(
//                Contact.HumanInfo.Item.Nickname.name(),
//                Contact.HumanInfo.Item.Avatar.name(),
//                Contact.HumanInfo.Item.Gender.name(),
//                Contact.HumanInfo.Item.Description.name(),
//                Contact.HumanInfo.Item.Addition.name()
//        ));
//        String separator = ":-:-:";
//
//        Helper.showSetDetails(this, checkList, separator, (result) -> {
//            HashMap<String, Contact.HumanInfo.Item> details = new HashMap<String, Contact.HumanInfo.Item>() {{
//                put(Contact.HumanInfo.Item.Nickname.name(), Contact.HumanInfo.Item.Nickname);
//                put(Contact.HumanInfo.Item.Avatar.name(), Contact.HumanInfo.Item.Avatar);
//                put(Contact.HumanInfo.Item.Gender.name(), Contact.HumanInfo.Item.Gender);
//                put(Contact.HumanInfo.Item.Description.name(), Contact.HumanInfo.Item.Description);
//                put(Contact.HumanInfo.Item.Addition.name(), Contact.HumanInfo.Item.Addition);
//            }};
//
//            String[] keyValue = result.split(separator);
//            Contact.HumanInfo.Item item = details.get(keyValue[0]);
//            String value = keyValue[1];
//
//            int ret = mContact.setHumanInfo(humanCode, item, value);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to set " + result + ". ret=" + ret);
//            }
//        });
//
//        return "";
//    }
//
//    private String showSetWalletAddress() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        LinkedList<String> checkList = new LinkedList<>(Arrays.asList(
//                "ELA",
//                "BTC",
//                "ETH"
//        ));
//        String separator = ":-:-:";
//
//        Helper.showSetDetails(this, checkList, separator, (result) -> {
//            String[] keyValue = result.split(separator);
//            String name = keyValue[0];
//            String value = keyValue[1];
//
//            int ret = mContact.setWalletAddress(name, value);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to set " + result + ". ret=" + ret);
//            }
//        });
//
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        return info.toString();
//    }
//
//    private String scanUserInfo() {
//        if (mContact == null) {
//            return (ErrorPrefix + "Contact is null.");
//        }
//
//        Helper.scanAddress(this, result -> {
//            showMessage(result);
//
//            Helper.showAddFriend(this, result, (summary) -> {
//                int ret = mContact.addFriend(result, summary);
//                if(ret < 0) {
//                    showMessage(ErrorPrefix + "Failed to add friend. ret=" + ret);
//                }
//            });
//        });
//
//        return "";
//    }
//
//    private String listFriendInfo() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        List<Contact.FriendInfo> friendList = mContact.listFriendInfo();
//        if(friendList == null) {
//            return ErrorPrefix + "Failed to list friend info.";
//        }
//        List<String> friendCodeList = mContact.listFriendCode();
//
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            Contact.FriendInfo friendInfo = null;
//            for(Contact.FriendInfo info: friendList) {
//                if(info.humanCode.equals(friendCode) == true) {
//                    friendInfo = info;
//                    break;
//                }
//            }
//            Helper.showDetails(MainActivity.this, friendInfo.toJson());
//        });
//        return "Success to list friend info.";
//    }
//
//    private String removeFriend() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//        String separator = " ";
//        List<String> friendCodeList = new ArrayList<>();
//        List<Contact.FriendInfo> friendList = mContact.listFriendInfo();
//        for(Contact.FriendInfo friendInfo : friendList) {
//            friendCodeList.add(friendInfo.humanCode + separator + "[" + friendInfo.status + "]");
//        }
//        Helper.showFriendList(this, friendCodeList, (result) -> {
//            String friendCode = result.split(separator)[0];
//
//            AlertDialog.Builder builder = new AlertDialog.Builder(this);
//            builder.setMessage("Are you sure to remove friend: " + friendCode);
//            builder.setPositiveButton("Delete", (dialog, which) -> {
//                int ret = mContact.removeFriend(friendCode);
//                if(ret < 0) {
//                    showMessage(ErrorPrefix + "Failed to delete friend. ret=" + ret);
//                    return;
//                }
//            });
//            builder.setNegativeButton("Cancel", (dialog, which) -> {
//                dialog.dismiss();
//            });
//            new Handler(Looper.getMainLooper()).post(() -> {
//                builder.create().show();
//            });
//        });
//        return "Success to send message.";
//    }
//
//    private String showSetFriendDetails() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        List<String> friendCodeList = new ArrayList<>();
//        List<Contact.FriendInfo> friendList = mContact.listFriendInfo();
//        for(Contact.FriendInfo friendInfo : friendList) {
//            friendCodeList.add(friendInfo.humanCode);
//        }
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            setHumanDetails(friendCode);
//        });
//        return "Success to send message.";
//    }
//
//    private String sendTextMessage() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//
//        List<String> friendCodeList = mContact.listFriendCode();
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            Helper.showTextSendMessage(this, friendCode, (message) -> {
//                Contact.Message msgInfo = Contact.MakeTextMessage(message, null);
////                StringBuffer str = new StringBuffer();
////                for(int idx = 0; idx < 1024 * 50; idx ++) {
////                    str.append("1234567890");
////                }
////                Contact.Message msgInfo = Contact.MakeTextMessage(str.toString(), null);
//
//                ContactStatus status = mContact.getStatus(friendCode);
//                if(status != ContactStatus.Online) {
//                    showMessage(ErrorPrefix + "Friend is not online.");
//                    return;
//                }
//
//                int ret = mContact.sendMessage(friendCode, ContactChannel.Carrier, msgInfo);
//                if(ret < 0) {
//                    showMessage(ErrorPrefix + "Failed to send message to " + friendCode);
//                }
//            });
//        });
//        return "Success to send text message.";
//    }
//
//    private String sendBinaryMessage() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//
//        List<String> friendCodeList = mContact.listFriendCode();
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            ContactStatus status = mContact.getStatus(friendCode);
//            if(status != ContactStatus.Online) {
//                showMessage(ErrorPrefix + "Friend is not online.");
//                return;
//            }
//
//            Contact.Message msgInfo = Contact.MakeBinaryMessage(new byte[]{0, 1, 2, 3}, null);
//            int ret = mContact.sendMessage(friendCode, ContactChannel.Carrier, msgInfo);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to send message to " + friendCode);
//            }
//
//            Helper.dismissDialog();
//        });
//        return "Success to send binary message.";
//    }
//
//
//    private String sendFileMessage() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//
//        List<String> friendCodeList = mContact.listFriendCode();
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            Helper.showFileSendMessage(this, friendCode, (filepath) -> {
//                Contact.Message msgInfo = Contact.MakeFileMessage(new File(filepath), null);
//
//                ContactStatus status = mContact.getStatus(friendCode);
//                if(status != ContactStatus.Online) {
//                    showMessage(ErrorPrefix + "Friend is not online.");
//                    return;
//                }
//
//                int ret = mContact.sendMessage(friendCode, ContactChannel.Carrier, msgInfo);
//                if(ret < 0) {
//                    showMessage(ErrorPrefix + "Failed to send message to " + friendCode);
//                }
//
//                mContactSendFileMap.put(msgInfo.data.toString(), filepath);
//            });
//        });
//        return "Success to send file message.";
//    }
//
//    private String pullFile() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//        List<String> friendCodeList = new ArrayList<>(mContactRecvFileMap.keySet());
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            Helper.dismissDialog();
//
//            ContactStatus status = mContact.getStatus(friendCode);
//            if(status != ContactStatus.Online) {
//                showMessage(ErrorPrefix + "Friend is not online.");
//                return;
//            }
//
//            Contact.Message.FileData fileData = mContactRecvFileMap.get(friendCode);
//            int ret = mContact.pullFileAsync(friendCode, ContactChannel.Carrier, fileData);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to pull file from " + friendCode);
//            }
//        });
//        return "Success to start pull file.";
//    }
//
//    private String cancelPullFile() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//        Contact.UserInfo info = mContact.getUserInfo();
//        if(info == null) {
//            return ErrorPrefix + "Failed to get user info.";
//        }
//
//        if (info.status != ContactStatus.Online) {
//            return ErrorPrefix + "Contact is not online.";
//        }
//
//        List<String> friendCodeList = new ArrayList<>(mContactRecvFileMap.keySet());
//        Helper.showFriendList(this, friendCodeList, (friendCode) -> {
//            ContactStatus status = mContact.getStatus(friendCode);
//            if(status != ContactStatus.Online) {
//                showMessage(ErrorPrefix + "Friend is not online.");
//                return;
//            }
//
//            Contact.Message.FileData fileData = mContactRecvFileMap.get(friendCode);
//            int ret = mContact.cancelPullFile(friendCode, ContactChannel.Carrier, fileData);
//            if(ret < 0) {
//                showMessage(ErrorPrefix + "Failed to cancel pull file from " + friendCode);
//            }
//
//            Helper.dismissDialog();
//        });
//        return "Success to cancel pull file.";
//    }
//
//    private String getCachedDidProp() {
//        if (mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        StringBuffer cachedDidProp = new StringBuffer();
//        Contact.Debug.GetCachedDidProp(cachedDidProp);
//        Helper.showDetails(MainActivity.this, cachedDidProp.toString());
//        return "Success to get cached didprop.";
//    }
//
//    private String testSyncUpload() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        int ret = mContact.syncInfoUploadToDidChain();
//        if(ret < 0) {
//            return ErrorPrefix + "Failed to call syncInfoUploadToDidChain() ret=" + ret;
//        }
//
//        return "Success to syncInfoUploadToDidChain.";
//    }
//
//    private String testSyncDownload() {
//        if(mContact == null) {
//            return ErrorPrefix + "Contact is null.";
//        }
//
//        int ret = mContact.syncInfoDownloadFromDidChain();
//        if(ret < 0) {
//            return ErrorPrefix + "Failed to call syncInfoDownloadToDidChain() ret=" + ret;
//        }
//
//        return "Success to syncInfoDownloadToDidChain.";
//    }
//
//    private byte[] processAcquire(AcquireArgs request) {
//        byte[] response = null;
//
//        switch (request.type) {
//            case PublicKey:
//                response = getPublicKey().getBytes();
//                break;
//            case EncryptData:
//                response = request.data; // plaintext
//                break;
//            case DecryptData:
//                response = request.data; // plaintext
//                break;
//            case DidPropAppId:
////                String appId = "DC92DEC59082610D1D4698F42965381EBBC4EF7DBDA08E4B3894D530608A64AAA65BB82A170FBE16F04B2AF7B25D88350F86F58A7C1F55CC29993B4C4C29E405";
////                response = appId.getBytes();
//                response = null;
//                break;
//            case DidAgentAuthHeader:
//                response = getAgentAuthHeader();
//                break;
//            case SignData:
//                response = signData(request.data);
//                break;
//            default:
//                throw new RuntimeException("Unprocessed request: " + request);
//        }
//
//
//        return response;
//    }
//
//    private void processEvent(EventArgs event) {
//        switch (event.type) {
//            case StatusChanged:
//                break;
//            case FriendRequest:
//                Contact.Listener.RequestEvent requestEvent = (Contact.Listener.RequestEvent) event;
//                Helper.showFriendRequest(this, requestEvent.humanCode, requestEvent.summary, v -> {
//                    mContact.acceptFriend(requestEvent.humanCode);
//                });
//                break;
//            case HumanInfoChanged:
//                Contact.Listener.InfoEvent infoEvent = (Contact.Listener.InfoEvent) event;
//                String msg = event.humanCode + " info changed: " + infoEvent.toString();
//                showEvent(msg);
//                break;
//            default:
//                Log.w(TAG, "Unprocessed event: " + event);
//        }
//    }
//
//    private String getPublicKey() {
//        ElastosKeypair.Data seedData = new ElastosKeypair.Data();
//        int seedSize = ElastosKeypair.getSeedFromMnemonic(seedData, mSavedMnemonic,
//                                                          KeypairLanguage, KeypairWords, "");
//        String pubKey = ElastosKeypair.getSinglePublicKey(seedData, seedSize);
//        return pubKey;
//    }
//
//    private String getPrivateKey() {
//        ElastosKeypair.Data seedData = new ElastosKeypair.Data();
//        int seedSize = ElastosKeypair.getSeedFromMnemonic(seedData, mSavedMnemonic,
//                KeypairLanguage, KeypairWords, "");
//        String privKey = ElastosKeypair.getSinglePrivateKey(seedData, seedSize);
//        return privKey;
//    }
//
//    private byte[] getAgentAuthHeader() {
//        String appid = "org.elastos.debug.didplugin";
//        String appkey = "b2gvzUM79yLhCbbGNWCuhSsGdqYhA7sS";
//        long timestamp = System.currentTimeMillis();
//        String auth = Utils.getMd5Sum(appkey + timestamp);
//        String headerValue = "id=" + appid + ";time=" + timestamp + ";auth=" + auth;
//        Log.i(TAG, "getAgentAuthHeader() headerValue=" + headerValue);
//
//        return headerValue.getBytes();
//    }
//
//    private byte[] signData(byte[] data) {
//        String privKey = getPrivateKey();
//
//        ElastosKeypair.Data originData = new ElastosKeypair.Data();
//        originData.buf = data;
//
//        ElastosKeypair.Data signedData = new ElastosKeypair.Data();
//
//        int signedSize = ElastosKeypair.sign(privKey, originData, originData.buf.length, signedData);
//        if(signedSize <= 0) {
//            return null;
//        }
//
//        return signedData.buf;
//    }
//
//    private String getDeviceId() {
//        String devId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
//        return devId;
//    }
//
//    public void showMessage(String msg) {
//        Handler handler = new Handler(Looper.getMainLooper());
//        handler.post(() -> {
//            Log.i(TAG, msg);
//            TextView txtMsg = findViewById(R.id.txt_message);
//            txtMsg.setText(msg);
//
//            if(msg.startsWith(ErrorPrefix)) {
//                showToast(msg);
//            }
//        });
//    }
//
//    public void showEvent(String newMsg) {
//        Handler handler = new Handler(Looper.getMainLooper());
//        handler.post(() -> {
//            Log.i(TAG, newMsg);
//
//            TextView txtCbMsg = findViewById(R.id.txt_event);
//            String msg = txtCbMsg.getText().toString();
//            msg += "\n";
//            msg += newMsg;
//            txtCbMsg.setText(msg);
//        });
//    }
//
//    public void showError(String newErr) {
//        Handler handler = new Handler(Looper.getMainLooper());
//        handler.post(() -> {
//            Log.e(TAG, newErr);
//
//            TextView txtCbMsg = findViewById(R.id.txt_error);
//            txtCbMsg.setText(newErr);
//        });
//    }
//
    public void showToast(String msg) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(() -> {
            if(mToast != null) {
                mToast.cancel();
            }
            mToast = Toast.makeText(this, msg, Toast.LENGTH_LONG);
            mToast.show();
        });
    }

    private void setClip(String data) {
        ClipboardManager cManager = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData cData = ClipData.newPlainText("text", data);
        cManager.setPrimaryClip(cData);
        showToast("Copied.");
    }
//
//    private String newAndSaveMnemonic(final String newMnemonic) {
//        mSavedMnemonic = newMnemonic;
//        if(mSavedMnemonic == null) {
//            mSavedMnemonic = ElastosKeypair.generateMnemonic(KeypairLanguage, KeypairWords);
//        }
//
//        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
//        SharedPreferences.Editor editor = pref.edit();
//        editor.putString(SavedMnemonicKey, mSavedMnemonic).commit();
//        if(mContact == null) { // noneed to restart
//            return ("Success to save mnemonic:\n" + mSavedMnemonic);
//        }
//
//        AlertDialog.Builder builder = new AlertDialog.Builder(this);
//        builder.setMessage("New mnemonic can only be valid after restart,\ndo you want restart app?");
//        builder.setPositiveButton("Restart", (dialog, which) -> {
//            // restart
//            Intent mStartActivity = new Intent(this, MainActivity.class);
//            int mPendingIntentId = 123456;
//            PendingIntent mPendingIntent = PendingIntent.getActivity(this, mPendingIntentId, mStartActivity, PendingIntent.FLAG_CANCEL_CURRENT);
//            AlarmManager mgr = (AlarmManager)this.getSystemService(Context.ALARM_SERVICE);
//            mgr.set(AlarmManager.RTC, System.currentTimeMillis() + 100, mPendingIntent);
//            Process.killProcess(Process.myPid());
//        });
//        builder.setNegativeButton("Cancel", (dialog, which) -> {
//            dialog.dismiss();
//        });
//        new Handler(Looper.getMainLooper()).post(() -> {
//            builder.create().show();
//        });
//
//        return ("Cancel to save mnemonic:\n" + newMnemonic);
//    }
//
//    @Override
//    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
//        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
//
//        Helper.onRequestPermissionsResult(this, requestCode, permissions, grantResults);
//    }
//
//    @Override
//    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
//        super.onActivityResult(requestCode, resultCode, data);
//
//        Helper.onActivityResult(this, requestCode, resultCode, data);
//    }
//
//    private boolean isEnglishWords(String words) {
//        boolean isEnglish = Charset.forName("US-ASCII").newEncoder().canEncode(words);
//        return isEnglish;
//    }
//
//    String mSavedMnemonic;
    Contact mContact;
//    Contact.Listener mContactListener;
//    Contact.DataListener mContactDataListener;
//    HashMap<String, Contact.Message.FileData> mContactRecvFileMap = new HashMap<>();
//    HashMap<String, String> mContactSendFileMap = new HashMap<>();
//
//    Thread mThread;
    Toast mToast;
//
//    private static final String ErrorPrefix = "Error: ";
//
//    private static final String KeypairLanguage = "english";
//    private static final String KeypairWords = "";
//
//    private static final String SavedMnemonicKey = "mnemonic";
//
//
//    private static final String UploadedMnemonic1 = "grab fiber sail lonely film salmon seven tackle solid news ribbon giggle";
//    private static final String UploadedMnemonic2 = "rare diamond fit plastic friend pull hollow adjust radar fun hedgehog endless";
}
