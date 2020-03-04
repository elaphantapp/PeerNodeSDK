package app.elaphant.sdk.peernode;

import android.util.Log;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class PeerNode {
    private static final String TAG = PeerNode.class.getName();
    public static String CHAT_SERVICE_NAME = "chat";

    private static PeerNode sInstance = null;

    final static byte[] PROTOCOL_APPEND_DATA = new byte[]{(byte) 0xC3, (byte) 0x83,
            (byte) 0xC3, (byte) 0x83, (byte) 0xC3, (byte) 0x83, (byte) 0xC3, (byte) 0x83};

    private Contact mContact;
    private PeerNodeListener.Listener mListener;
    private final Map<String, List<PeerNodeListener.MessageListener>> mMessageListeners = new HashMap<>();
    private final Map<String, List<PeerNodeListener.DataListener>> mDataListeners = new HashMap<>();

    private PeerNode(String path, String deviceId) {
        Contact.Factory.SetLogLevel(7);
        Contact.Factory.SetDeviceId(deviceId);
        Contact.Factory.SetLocalDataDir(path);

        mContact = Contact.Factory.Create();
        Contact.Listener contactListener = new Contact.Listener() {
            @Override
            public byte[] onAcquire(AcquireArgs request) {
                synchronized (PeerNodeListener.Listener.class) {
                    return mListener.onAcquire(request);
                }
            }

            @Override
            public void onEvent(EventArgs event) {
                if (mMessageListeners.size() == 0) return;
                if (event.type == EventArgs.Type.FriendRequest) {
                    synchronized (mMessageListeners) {
                        RequestEvent requestEvent = (RequestEvent) event;
                        StringBuffer content = new StringBuffer();
                        List<PeerNodeListener.MessageListener> listeners = findMsgListener(requestEvent.summary, content);
                        if (listeners == null) return;

                        requestEvent.summary = content.toString();
                        for (PeerNodeListener.MessageListener listener : listeners) {
                            listener.onEvent(event);
                        }
                    }
                } else {
                    synchronized (mMessageListeners) {
                        for (List<PeerNodeListener.MessageListener> listeners : mMessageListeners.values()) {
                            for (PeerNodeListener.MessageListener listener : listeners) {
                                listener.onEvent(event);
                            }
                        }
                    }
                }
            }

            @Override
            public void onReceivedMessage(String humanCode, Contact.Channel channelType, Contact.Message message) {
                String msg = "onRcvdMsg(): data=" + message.data + "\n";
                msg += "onRcvdMsg(): type=" + message.type + "\n";
                msg += "onRcvdMsg(): crypto=" + message.cryptoAlgorithm + "\n";
                Log.d(TAG, msg);

                if (message.type == Contact.Message.Type.MsgText) {
                    synchronized (mMessageListeners) {
                        StringBuffer content = new StringBuffer();
                        List<PeerNodeListener.MessageListener> listeners = findMsgListener(message.data.toString(), content);
                        if (listeners == null) return;

                        for (PeerNodeListener.MessageListener listener : listeners) {
                            listener.onReceivedMessage(humanCode, channelType, Contact.MakeTextMessage(content.toString(), null));
                        }
                    }
                } else if (message.type == Contact.Message.Type.MsgBinary) {
                    synchronized (mMessageListeners) {
                        distributeBinary(humanCode, channelType, message.data.toData());
                    }
                }
            }

            @Override
            public void onError(int errCode, String errStr, String ext) {
                String msg = errCode + ": " + errStr + "\n" + ext;;
                Log.e(TAG, msg);
                synchronized (PeerNodeListener.Listener.class) {
                    mListener.onError(errCode, errStr, ext);
                }
            }
        };
        mContact.setListener(contactListener);

        Contact.DataListener contactDataListener = new Contact.DataListener() {
            @Override
            public void onNotify(String humanCode, Contact.Channel channelType,
                                 String dataId, Status status) {
                String msg = "onNotify(): dataId=" + dataId + ", status=" + status + "\n";
                Log.d(TAG, msg);
            }

            @Override
            public int onReadData(String humanCode, Contact.Channel channelType,
                                  String dataId, long offset, ByteBuffer data) {
                return 0;
            }

            @Override
            public int onWriteData(String humanCode, Contact.Channel channelType,
                                   String dataId, long offset, byte[] data) {
                return 0;
            }
        };
        mContact.setDataListener(contactDataListener);
    }


    private List<PeerNodeListener.MessageListener> findMsgListener(String summary, StringBuffer content) {
        List<PeerNodeListener.MessageListener> lis = null;
        try {
            JSONObject jobj = new JSONObject(summary);
            String name = jobj.getString("serviceName");
            content.append(jobj.getString("content"));
            lis = mMessageListeners.get(name.toLowerCase());
        } catch (JSONException e) {
            e.printStackTrace();
            content.append(summary);
        }

        if (lis == null) {
            lis = mMessageListeners.get(CHAT_SERVICE_NAME);
        }
        return lis;
    }

    private void distributeBinary(String humanCode, Contact.Channel channelType, byte[] data) {
        List<PeerNodeListener.MessageListener> lis = null;

        int len = data.length > 100 ? 100 : data.length;
        byte[] protocol = new byte[len];

        System.arraycopy(data, 0, protocol, 0, len);
        String src = new String(protocol);
        String append = new String(PROTOCOL_APPEND_DATA);
        int index = src.indexOf(append);

        byte[] content = null;
        if (index >= 0) {
            byte[] json = Arrays.copyOfRange(data, 0, index);
            String str = new String(json);

            try {
                JSONObject jobj = new JSONObject(str);
                String name = jobj.getString("serviceName");
                lis = mMessageListeners.get(name.toLowerCase());
                content = Arrays.copyOfRange(data, index + PROTOCOL_APPEND_DATA.length, data.length);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if (lis == null) {
            content = data;
            lis = mMessageListeners.get(CHAT_SERVICE_NAME);
        }

        if (lis == null) return;

        for (PeerNodeListener.MessageListener listener : lis) {
            listener.onReceivedMessage(humanCode, channelType, Contact.MakeBinaryMessage(content, null));
        }
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
        synchronized (mMessageListeners) {
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
        synchronized (mMessageListeners) {
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
        synchronized (mDataListeners) {
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
        synchronized (mDataListeners) {
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

    public int appendChannelStrategy(Contact.ChannelStrategy strategy) {
        return mContact.appendChannelStrategy(strategy);
    }

    public int setUserInfo(Contact.HumanInfo.Item item, String value) {
        return mContact.setUserInfo(item, value);
    }

    public Contact.UserInfo getUserInfo() {
        return mContact.getUserInfo();
    }

    public int getUserBrief(StringBuffer brief) {
        return mContact.getUserBrief(brief);
    }

    public int setIdentifyCode(Contact.UserInfo.Type type, String value) {
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

    public int setFriendInfo(String humanCode, Contact.HumanInfo.Item item, String value) {
        return mContact.setHumanInfo(humanCode, item, value);
    }

    public List<Contact.FriendInfo> listFriendInfo() {
        return mContact.listFriendInfo();
    }

    public List<String> listFriendCode() {
        return mContact.listFriendCode();
    }

    public Contact.Status getStatus() {
        return mContact.getStatus("-user-info-");
    }

    public Contact.Status getFriendStatus(String friendCode) {
        return mContact.getStatus(friendCode);
    }

    public int sendMessage(String friendCode, Contact.Channel channel, Contact.Message message) {
        return mContact.sendMessage(friendCode, channel, message);
    }

    public int pullFileAsync(String friendCode, Contact.Message.FileData fileInfo) {
        return mContact.pullFileAsync(friendCode, Contact.Channel.Carrier, fileInfo);
    }

    public int cancelPullFile(String friendCode, Contact.Message.FileData fileInfo) {
        return mContact.cancelPullFile(friendCode, Contact.Channel.Carrier, fileInfo);
    }

    public int setWalletAddress(String name, String value) {
        return mContact.setWalletAddress(name, value);
    }

    public int exportUserData(String toFile) {
        return mContact.exportUserData(toFile);
    }

    public int importUserData(String fromFile) {
        return mContact.importUserData(fromFile);
    }
}
