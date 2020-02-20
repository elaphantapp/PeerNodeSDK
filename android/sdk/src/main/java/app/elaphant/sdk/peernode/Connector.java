package app.elaphant.sdk.peernode;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public final class Connector {
    private static final String TAG = Connector.class.getName();

    private PeerNode mPeerNode = null;
    private String mServiceName;

    private PeerNodeListener.MessageListener mMessagListener = null;
    private PeerNodeListener.DataListener mDataListener = null;

    public Connector(String serviceName) {
        mPeerNode = PeerNode.getInstance();
        if (serviceName == null || serviceName.isEmpty()) {
            mServiceName = PeerNode.CHAT_SERVICE_NAME;
        } else {
            mServiceName = serviceName;
        }
    }

    public void finalize() {
        removeMessageListener();
        removeDataListener();
    }

    public void setMessageListener(PeerNodeListener.MessageListener listener) {
        if (mPeerNode == null) return;
        if (mMessagListener != null) {
            removeMessageListener();
        }
        mPeerNode.addMessageListener(mServiceName, listener);
        mMessagListener = listener;
    }

    public void removeMessageListener() {
        if (mPeerNode == null) return;
        mPeerNode.removeMessageListener(mServiceName, mMessagListener);
        mMessagListener = null;
    }

    public void setDataListener(PeerNodeListener.DataListener listener) {
        if (mPeerNode == null) return;
        if (mDataListener != null) {
            removeDataListener();
        }
        mPeerNode.addDataListener(mServiceName, listener);
        mDataListener = listener;
    }

    public void removeDataListener() {
        if (mPeerNode == null) return;
        if (mDataListener == null) return;
        mPeerNode.removeDataListener(mServiceName, mDataListener);
        mDataListener = null;
    }

    public Contact.UserInfo getUserInfo() {
        return mPeerNode.getUserInfo();
    }

    public int addFriend(String friendCode, String summary) {
        if (mPeerNode == null) return -1;

        JSONObject json = new JSONObject();
        try {
            json.put("serviceName", mServiceName);
            json.put("content", summary);
            return mPeerNode.addFriend(friendCode, json.toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return -1;
    }

    public int removeFriend(String friendCode) {
        if (mPeerNode == null) return -1;
        return mPeerNode.removeFriend(friendCode);
    }

    public int acceptFriend(String friendCode) {
        if (mPeerNode == null) return -1;
        return mPeerNode.acceptFriend(friendCode);
    }

    public int setFriendInfo(String humanCode, Contact.HumanInfo.Item item, String value) {
        if (mPeerNode == null) return -1;
        return mPeerNode.setFriendInfo(humanCode, item, value);
    }

    public List<Contact.FriendInfo> listFriendInfo() {
        if (mPeerNode == null) return null;
        return mPeerNode.listFriendInfo();
    }

    public List<String> listFriendCode() {
        if (mPeerNode == null) return null;
        return mPeerNode.listFriendCode();
    }

    public Contact.Status getStatus() {
        if (mPeerNode == null) return Contact.Status.Invalid;
        return mPeerNode.getStatus();
    }

    public Contact.Status getFriendStatus(String friendCode) {
        if (mPeerNode == null) return Contact.Status.Invalid;
        return mPeerNode.getFriendStatus(friendCode);
    }

    public int sendMessage(String friendCode, Contact.Channel channel, String message) {
        if (mPeerNode == null) return -1;

        boolean isDidFriend = Contact.IsDidFriend(friendCode);

        String data;
        if (isDidFriend) {
            try {
                JSONObject json = new JSONObject();
                json.put("serviceName", mServiceName);
                json.put("content", message);
                data = json.toString();
            } catch (JSONException e) {
                e.printStackTrace();
                return -1;
            }
        } else {
            data = message;
        }

        return mPeerNode.sendMessage(friendCode, channel, Contact.MakeTextMessage(data, null));
    }

    public int sendBinaryMessage(String friendCode, Contact.Channel channel, byte[] binary) {
        if (mPeerNode == null) return -1;

        boolean isDidFriend = Contact.IsDidFriend(friendCode);

        byte[] data;
        if (isDidFriend) {
            try {
                JSONObject json = new JSONObject();
                json.put("serviceName", mServiceName);
                json.put("content", "binary");
                byte[] protocol = json.toString().getBytes();
                data = new byte[protocol.length + PeerNode.PROTOCOL_APPEND_DATA.length + binary.length];
                System.arraycopy(protocol, 0, data, 0, protocol.length);
                System.arraycopy(PeerNode.PROTOCOL_APPEND_DATA, 0, data, protocol.length, PeerNode.PROTOCOL_APPEND_DATA.length);
                System.arraycopy(binary, 0, data, protocol.length + PeerNode.PROTOCOL_APPEND_DATA.length, binary.length);
            } catch (JSONException e) {
                e.printStackTrace();
                return -1;
            }
        } else {
            data = binary;
        }

        return mPeerNode.sendMessage(friendCode, channel, Contact.MakeBinaryMessage(data, null));
    }
}
