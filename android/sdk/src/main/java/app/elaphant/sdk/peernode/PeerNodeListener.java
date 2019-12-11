package app.elaphant.sdk.peernode;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.elastos.sdk.elephantwallet.contact.internal.ContactChannel;
import org.elastos.sdk.elephantwallet.contact.internal.ContactDataListener;
import org.elastos.sdk.elephantwallet.contact.internal.ContactListener;

import java.nio.ByteBuffer;

public class PeerNodeListener {

    public interface Listener {
        byte[] onAcquire(ContactListener.AcquireArgs request);
        void onError(int errCode, String errStr, String ext);
    }

    public interface MessageListener {
        void onEvent(ContactListener.EventArgs event);
        void onReceivedMessage(String humanCode, ContactChannel channelType, Contact.Message message);
    }

    public interface DataListener {
        void onNotify(String humanCode, ContactChannel channelType,
                                      String dataId, ContactDataListener.Status status);
        int onReadData(String humanCode, ContactChannel channelType,
                                       String dataId, long offset, ByteBuffer data);
        int onWriteData(String humanCode, ContactChannel channelType,
                                        String dataId, long offset, byte[] data);
    }


}
