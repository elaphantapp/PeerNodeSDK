package app.elaphant.sdk.peernode.test;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.os.Process;
import android.provider.Settings;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.elastos.sdk.elephantwallet.contact.Utils;
import org.elastos.sdk.keypair.ElastosKeypair;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;


import app.elaphant.sdk.peernode.Connector;
import app.elaphant.sdk.peernode.PeerNode;
import app.elaphant.sdk.peernode.PeerNodeListener;

public class MainActivity extends Activity {
    private static final String TAG = "PeerNodeTest";

    private static final String mnemonic = "ability cloth cannon buddy together theme uniform erase fossil meadow top pumpkin";
    private static final String mPrivateKey = "b8e923f4e5c5a3c704bcc02a90ee0e4fa34a5b8f0dd1de1be4eb2c37ffe8e3ea";
    private static final String mPublicKey = "021e53dc2b8af1548175cba357ae321096065f8d49e3935607bc8844c157bb0859";

    private PeerNode mPeerNode;

    private TextView mError;
    private TextView mMessage;
    private TextView mEvent;

    private Connector mConnector = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mError = findViewById(R.id.txt_error);
        mMessage = findViewById(R.id.txt_message);
        mEvent = findViewById(R.id.txt_event);

        mPeerNode = PeerNode.getInstance(getFilesDir().getAbsolutePath(),
                Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID));

        mPeerNode.setListener(new PeerNodeListener.Listener() {
            @Override
            public byte[] onAcquire(Contact.Listener.AcquireArgs request) {
                byte[] response = null;
                switch (request.type) {
                    case PublicKey:
                        response = mPublicKey.getBytes();
                        break;
                    case EncryptData:
                        response = request.data;
                        break;
                    case DecryptData:
                        response = request.data;
                        break;
                    case DidPropAppId:
                        break;
                    case DidAgentAuthHeader:
                        response = getAgentAuthHeader();
                        break;
                    case SignData:
                        response = signData(request.data);
                        break;
                    default:
                        throw new RuntimeException("Unprocessed request: " + request);
                }
                return response;
            }

            @Override
            public void onError(int errCode, String errStr, String ext) {
                showError("Contact error: " + errCode + " " + errStr);
            }
        });

        mPeerNode.start();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mPeerNode.stop();

        Process.killProcess(Process.myPid());
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        if (item.getItemId() == R.id.create_service) {
            return createConnector();
        } else if (item.getItemId() == R.id.send_msg) {
            return sendMessage();
        } else if (item.getItemId() == R.id.add_friend) {
            addFriend();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private byte[] getAgentAuthHeader() {
        String appid = "org.elastos.debug.didplugin";
        String appkey = "b2gvzUM79yLhCbbGNWCuhSsGdqYhA7sS";
        long timestamp = System.currentTimeMillis();
        String auth = Utils.getMd5Sum(appkey + timestamp);
        String headerValue = "id=" + appid + ";time=" + timestamp + ";auth=" + auth;
        Log.i(TAG, "getAgentAuthHeader() headerValue=" + headerValue);

        return headerValue.getBytes();
    }

    private byte[] signData(byte[] data) {

        ElastosKeypair.Data originData = new ElastosKeypair.Data();
        originData.buf = data;

        ElastosKeypair.Data signedData = new ElastosKeypair.Data();

        int signedSize = ElastosKeypair.sign(mPrivateKey, originData, originData.buf.length, signedData);
        if(signedSize <= 0) {
            return null;
        }

        return signedData.buf;
    }

    private boolean createConnector() {
        if (mConnector != null) return false;
        mConnector = new Connector("Test");
        mConnector.setMessageListener(new PeerNodeListener.MessageListener() {
            @Override
            public void onEvent(Contact.Listener.EventArgs event) {
                showEvent(event);
            }

            @Override
            public void onReceivedMessage(String humanCode, Contact.Channel channelType, Contact.Message message) {
                showMessage(humanCode, message);
            }
        });

        return false;
    }

    private boolean sendMessage() {
        if (mConnector == null) {
            Toast.makeText(this, "please create connector first!", Toast.LENGTH_LONG).show();
            return false;
        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Select a friend");
        builder.setNegativeButton("cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });

        List<String> friends = mConnector.listFriendCode();
        final ArrayAdapter<String> arrayAdapter = new ArrayAdapter<String>(this, android.R.layout.select_dialog_singlechoice);
        assert friends != null;
        arrayAdapter.addAll(friends);
        builder.setAdapter(arrayAdapter, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                send(arrayAdapter.getItem(which));
                dialog.dismiss();
            }
        });
        builder.create().show();

        return false;
    }

    private void send(String friendCode) {
        final EditText edit = new EditText(this);
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Input message");

        builder.setView(edit);
        builder.setNegativeButton("cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        builder.setPositiveButton("ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String message = edit.getText().toString().trim();
                if (message.isEmpty()) return;

                mConnector.sendMessage(friendCode, message);
            }
        });
        builder.create().show();
    }

    private void showEvent(Contact.Listener.EventArgs event) {
        String text = "";
        switch (event.type) {
            case FriendRequest:
                Contact.Listener.RequestEvent requestEvent = (Contact.Listener.RequestEvent) event;
                String summary = requestEvent.summary;
                text = requestEvent.humanCode + " request friend, said: " + summary;
                mConnector.acceptFriend(requestEvent.humanCode);
                break;
            case StatusChanged:
                Contact.Listener.StatusEvent statusEvent = (Contact.Listener.StatusEvent)event;
                text = statusEvent.humanCode + " status changed " + statusEvent.status;
                break;
            case HumanInfoChanged:
                Contact.Listener.InfoEvent infoEvent = (Contact.Listener.InfoEvent) event;
                text = event.humanCode + " info changed: " + infoEvent.toString();
                break;
            default:
                Log.w(TAG, "Unprocessed event: " + event);
                return;
        }
        String finalText = text;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mEvent.setText(finalText);
            }
        });

    }

    private void showMessage(String humanCode, Contact.Message message) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mMessage.setText("Receive message from " + humanCode + " " + message.data.toString());
            }
        });
    }

    private void showError(String text) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mError.setText(text);
            }
        });
    }

    private void addFriend() {
        final EditText edit = new EditText(this);
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Input DID");

        builder.setView(edit);
        builder.setNegativeButton("cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        builder.setPositiveButton("ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String friendCode = edit.getText().toString().trim();
                if (friendCode.isEmpty()) return;

                mConnector.addFriend(friendCode, "hello");
            }
        });
        builder.create().show();
    }
}
