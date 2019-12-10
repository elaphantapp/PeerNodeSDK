package app.elaphant.sdk.peernode;

import android.util.Log;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.elastos.sdk.elephantwallet.contact.internal.ContactChannel;
import org.elastos.sdk.elephantwallet.contact.internal.ContactStatus;
import org.elastos.sdk.elephantwallet.contact.internal.HumanInfo;
import org.elastos.sdk.elephantwallet.contact.internal.IdentifyCode;
import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class PeerNode {
    private static final String TAG = PeerNode.class.getName();

    private static PeerNode sInstance = null;

    private Contact mContact;
    private PeerNodeListener.Listener mListener;
    private final Object mListenerLock = new Object();

    private Map<String, List<PeerNodeListener.MessageListener>> mMessageListeners = new HashMap<>();
    private final Object mMsgListenerLock = new Object();

    private Map<String, List<PeerNodeListener.DataListener>> mDataListeners = new HashMap<>();
    private final Object mDataListenerLock = new Object();

    private PeerNode(String path, String deviceId) {
        Contact.Factory.SetLogLevel(7);
        Contact.Factory.SetDeviceId(deviceId);
        Contact.Factory.SetLocalDataDir(path);

        mContact = Contact.Factory.Create();
        Contact.Listener contactListener = new Contact.Listener() {
            @Override
            public byte[] onAcquire(AcquireArgs request) {
                synchronized (mListenerLock) {
                    return mListener.onAcquire(request);
                }
            }

            @Override
            public void onEvent(EventArgs event) {
                if (mMessageListeners.size() == 0) return;
                if (event.type == EventArgs.Type.FriendRequest) {
                    synchronized (mMsgListenerLock) {
                        RequestEvent requestEvent = (RequestEvent) event;
                        List<PeerNodeListener.MessageListener> listeners = findMsgListener(requestEvent.summary);
                        if (listeners == null) return;

                        for (PeerNodeListener.MessageListener listener : listeners) {
                            listener.onEvent(event);
                        }
                    }
                } else {
                    synchronized (mMsgListenerLock) {
                        for (List<PeerNodeListener.MessageListener> listeners : mMessageListeners.values()) {
                            for (PeerNodeListener.MessageListener listener : listeners) {
                                listener.onEvent(event);
                            }
                        }
                    }
                }
            }

            @Override
            public void onReceivedMessage(String humanCode, ContactChannel channelType, Contact.Message message) {
                String msg = "onRcvdMsg(): data=" + message.data + "\n";
                msg += "onRcvdMsg(): type=" + message.type + "\n";
                msg += "onRcvdMsg(): crypto=" + message.cryptoAlgorithm + "\n";
                Log.d(TAG, msg);

                if (message.type == Contact.Message.Type.MsgText) {
                    synchronized (mMsgListenerLock) {
                        List<PeerNodeListener.MessageListener> listeners = findMsgListener(message.data.toString());
                        if (listeners == null) return;

                        for (PeerNodeListener.MessageListener listener : listeners) {
                            listener.onReceivedMessage(humanCode, channelType, message);
                        }
                    }
                }
            }

            @Override
            public void onError(int errCode, String errStr, String ext) {
                String msg = errCode + ": " + errStr + "\n" + ext;;
                Log.e(TAG, msg);
                synchronized (mListenerLock) {
                    mListener.onError(errCode, errStr, ext);
                }
            }
        };
        mContact.setListener(contactListener);

        Contact.DataListener contactDataListener = new Contact.DataListener() {
            @Override
            public void onNotify(String humanCode, ContactChannel channelType,
                                 String dataId, Status status) {
                String msg = "onNotify(): dataId=" + dataId + ", status=" + status + "\n";
                Log.d(TAG, msg);
            }

            @Override
            public int onReadData(String humanCode, ContactChannel channelType,
                                  String dataId, long offset, ByteBuffer data) {
                return 0;
            }

            @Override
            public int onWriteData(String humanCode, ContactChannel channelType,
                                   String dataId, long offset, byte[] data) {
                return 0;
            }
        };
        mContact.setDataListener(contactDataListener);
    }

    private List<PeerNodeListener.MessageListener> findMsgListener(String summary) {
        List<PeerNodeListener.MessageListener> lis = null;
        try {
            JSONObject jobj = new JSONObject(summary);
            String name = jobj.getString("serviceName");
            lis = mMessageListeners.get(name.toLowerCase());
        } catch (JSONException e) {
            e.printStackTrace();
        }

        if (lis == null) {
            lis = mMessageListeners.get("elaphantchat");
        }
        return lis;
    }

    public static PeerNode getInstance(String path, String deviceId) {
        if (sInstance == null) {
            sInstance = new PeerNode(path, deviceId);
        }

        return sInstance;
    }

    public static PeerNode getInstance() {
        return sInstance;
    }

    public void setListener(PeerNodeListener.Listener listener) {
        mListener = listener;
    }

    public void addMessageListener(String serviceName, PeerNodeListener.MessageListener listener) {
        synchronized (mMsgListenerLock) {
            String name = serviceName.toLowerCase();
            List<PeerNodeListener.MessageListener> listeners = mMessageListeners.get(name);
            if (listeners == null) {
                listeners = new ArrayList<>();
            }

            listeners.add(listener);
            mMessageListeners.put(name, listeners);
        }
    }

    public void removeMessageListener(String serviceName, PeerNodeListener.MessageListener listener) {
        synchronized (mMsgListenerLock) {
            String name = serviceName.toLowerCase();
            List<PeerNodeListener.MessageListener> listeners = mMessageListeners.get(name);
            if (listeners == null) return;

            listeners.remove(listener);
            if (listeners.size() == 0) {
                mMessageListeners.remove(name);
            } else {
                mMessageListeners.put(name, listeners);
            }
        }
    }

    public void addDataListener(String serviceName, PeerNodeListener.DataListener listener){
        synchronized (mDataListenerLock) {
            String name = serviceName.toLowerCase();
            List<PeerNodeListener.DataListener> listeners = mDataListeners.get(name);
            if (listeners == null) {
                listeners = new ArrayList<>();
            }

            listeners.add(listener);
            mDataListeners.put(name, listeners);
        }
    }

    public void removeDataListener(String serviceName, PeerNodeListener.DataListener listener) {
        synchronized (mDataListenerLock) {
            String name = serviceName.toLowerCase();
            List<PeerNodeListener.DataListener> listeners = mDataListeners.get(name);
            if (listeners == null) return;

            listeners.remove(listener);
            if (listeners.size() == 0) {
                mDataListeners.remove(name);
            } else {
                mDataListeners.put(name, listeners);
            }
        }
    }

    public int start() {
        int ret = mContact.start();
        mContact.syncInfoDownloadFromDidChain();
        mContact.syncInfoUploadToDidChain();
        return ret;
    }

    public int stop() {
        return mContact.stop();
    }

    public int setUserInfo(HumanInfo.Item item, String value) {
        return mContact.setUserInfo(item, value);
    }

    public Contact.UserInfo getUserInfo() {
        return mContact.getUserInfo();
    }

    public int setIdentifyCode(IdentifyCode.Type type, String value) {
        return mContact.setIdentifyCode(type, value);
    }

    public int addFriend(String friendCode, String summary) {
        return mContact.addFriend(friendCode, summary);
    }

    public int removeFriend(String friendCode) {
        return mContact.removeFriend(friendCode);
    }

    public int acceptFriend(String friendCode) {
        return mContact.acceptFriend(friendCode);
    }

    public int setFriendInfo(String humanCode, HumanInfo.Item item, String value) {
        return mContact.setHumanInfo(humanCode, item, value);
    }

    public List<Contact.FriendInfo> listFriendInfo() {
        return mContact.listFriendInfo();
    }

    public List<String> listFriendCode() {
        return mContact.listFriendCode();
    }

    public ContactStatus getStatus() {
        Contact.UserInfo userInfo = getUserInfo();
        return mContact.getStatus(userInfo.humanCode);
    }

    public ContactStatus getFriendStatus(String friendCode) {
        return mContact.getStatus(friendCode);
    }

    public int sendMessage(String friendCode, Contact.Message message) {
        return mContact.sendMessage(friendCode, ContactChannel.Carrier, message);
    }

    public int pullFileAsync(String friendCode, Contact.Message.FileData fileInfo) {
        return mContact.pullFileAsync(friendCode, ContactChannel.Carrier, fileInfo);
    }

    public int cancelPullFile(String friendCode, Contact.Message.FileData fileInfo) {
        return mContact.cancelPullFile(friendCode, ContactChannel.Carrier, fileInfo);
    }

    public int setWalletAddress(String name, String value) {
        return mContact.setWalletAddress(name, value);
    }
}
