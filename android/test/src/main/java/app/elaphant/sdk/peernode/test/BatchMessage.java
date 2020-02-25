package app.elaphant.sdk.peernode.test;

import android.app.Activity;
import android.app.AlertDialog;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.RadioGroup;

import org.elastos.sdk.elephantwallet.contact.Contact;
import org.elastos.sdk.elephantwallet.contact.internal.ContactInterface;

import java.util.List;

import app.elaphant.sdk.peernode.Connector;
import app.elaphant.sdk.peernode.PeerNode;
import app.elaphant.sdk.peernode.PeerNodeListener;

import static android.view.View.inflate;

public class BatchMessage {
    public static void showDialog(MainActivity activity) {
        Connector connector = getFeedbackConnector(activity);

        GridLayout rootView = (GridLayout) inflate(activity, R.layout.batch_send_message, null);

        AutoCompleteTextView friendCodeView = rootView.findViewById(R.id.friend_code);
        List<String> friendList = connector.listFriendCode();
        ArrayAdapter<String> adapter = new ArrayAdapter<>(activity,
                                                          android.R.layout.simple_dropdown_item_1line,
                                                          friendList);
        friendCodeView.setAdapter(adapter);
        friendCodeView.setThreshold(1);
        friendCodeView.setSingleLine();

        Button scanCodeButton = rootView.findViewById(R.id.scan_friend_code);
        scanCodeButton.setOnClickListener(v -> {
            Helper.scanAddress(activity, result -> {
                friendCodeView.setText(result);
            });
        });

        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle("Batch Message Test");
        builder.setView(rootView);
        rootView.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        builder.setNegativeButton("Cancel", (dialog, which) -> dialog.dismiss());
        builder.setPositiveButton("Ok", (dialog, which) -> {
            new Thread(() -> {
                trySendMessage(connector, activity, rootView, friendList);
            }).start();
        });
        builder.create().show();
    }

    private static Connector getFeedbackConnector(MainActivity activity) {
        if(sConnector != null) {
            return sConnector;
        }
        sConnector = new Connector("feedback");
        sConnector.setMessageListener(new PeerNodeListener.MessageListener() {
            @Override
            public void onEvent(Contact.Listener.EventArgs event) {
                activity.showEvent(event.toString());
            }

            @Override
            public void onReceivedMessage(String humanCode, Contact.Channel channelType, Contact.Message message) {
                String msg = "Receive message from " + humanCode + " " + message.data.toString();
                activity.showEvent(msg);
            }
        });

        return sConnector;
    }

    private static void trySendMessage(Connector connector, MainActivity activity, ViewGroup rootView,
                                       List<String> friendList) {
        AutoCompleteTextView friendCodeView = rootView.findViewById(R.id.friend_code);
        String friendCode = friendCodeView.getText().toString().trim();
        if (friendCode.isEmpty()) {
            activity.showEvent("Failed: Friend Code is empty");
            return;
        }
        activity.showEvent("try to batch send message to " + friendCode);

        boolean ret = ensureFriendOnline(connector, activity, friendCode, friendList);
        if(ret == false) {
            activity.showEvent("Failed: Ensure friend error");
            return;
        }

        ret = sendMessage(connector, activity, rootView, friendCode);
        if(ret == false) {
            activity.showEvent("Failed: Send Message error");
            return;
        }
    }

    private static boolean ensureFriendOnline(Connector connector, MainActivity activity,
                                              String friendCode, List<String> friendList) {
        if(friendList.contains(friendCode) == false) {
            int ret = connector.addFriend(friendCode, "batch test client");
            if(ret < 0) {
                activity.showEvent("Failed: Add Friend. ret=" + ret);
                return false;
            }
        }

        while (true) {
            activity.showEvent("Waiting for friend online...");

            Contact.Status status = connector.getFriendStatus(friendCode);
            if(status == Contact.Status.Online) {
                break;
            }

            try { Thread.sleep(5000); } catch (Exception e) { }
        }

        return true;
    }

    private static boolean sendMessage(Connector connector, MainActivity activity,
                                       ViewGroup rootView, String friendCode) {
        RadioGroup channelGroupView = rootView.findViewById(R.id.channel);
        Contact.Channel channel = Contact.Channel.Carrier;
        switch(channelGroupView.getCheckedRadioButtonId()) {
            case R.id.channel_custom:
                channel = activity.getCustomChannel();
                break;
        }

        EditText sendTimesView = rootView.findViewById(R.id.send_times);
        String sendTimesStr = sendTimesView.getText().toString();
        if(sendTimesStr.isEmpty()) {
            activity.showEvent("Failed: Send times is empty");
            return false;
        }
        int sendTimes = Integer.valueOf(sendTimesView.getText().toString());

        boolean ret = sendMessage(connector, activity, friendCode, channel, sendTimes);
        return ret;
    }

    private static boolean sendMessage(Connector connector, MainActivity activity,
                                       String friendCode, Contact.Channel channel, int sendTimes) {
        for(int idx = 0; idx < sendTimes; idx++) {
            int finalIdx = idx;
            new Thread(() -> {
                int ret = connector.sendMessage(friendCode, channel, "BatchMessage: " + finalIdx);
                activity.showEvent("Send `BatchMessage " + finalIdx + "` ret=" + ret);
            }).start();
        }

        return true;
    }

    private static Connector sConnector;
}
