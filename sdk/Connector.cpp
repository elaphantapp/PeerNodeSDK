
#include "Connector.h"
#include "Elastos.Wallet.Utility.h"

extern const std::vector<uint8_t> PROTOCOL_APPEND_DATA;

namespace elastos {

Connector::Connector(const std::string& serviceName)
    : mServiceName(serviceName)
{
    if (mServiceName.empty()) {
        mServiceName = CHAT_SERVICE_NAME;
    }
    mPeerNode = PeerNode::GetInstance();
}

Connector::~Connector()
{
    RemoveMessageListener();
    RemoveDataListener();
}

void Connector::SetMessageListener(std::shared_ptr<PeerListener::MessageListener>& listener)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return;
    }

    RemoveMessageListener();
    mPeerNode->AddMessageListener(mServiceName, listener);
    mMessageListener = listener;
}

void Connector::SetDataListener(std::shared_ptr<PeerListener::DataListener>& listener)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return;
    }

    RemoveDataListener();
    mPeerNode->AddDataListener(mServiceName, listener);
    mDataListener = listener;
}

void Connector::RemoveMessageListener()
{
    if (mPeerNode.get() == nullptr || mMessageListener.get() == nullptr) return;
    mPeerNode->RemoveMessageListener(mServiceName, mMessageListener);
    mMessageListener.reset();
}

void Connector::RemoveDataListener()
{
    if (mPeerNode.get() == nullptr || mDataListener.get() == nullptr) return;
    mPeerNode->RemoveDataListener(mServiceName, mDataListener);
    mDataListener.reset();
}

int Connector::AddFriend(const std::string& friendCode, const std::string& summary)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    Json json;
    json["serviceName"] = mServiceName;
    json["content"] = summary;

    return mPeerNode->AddFriend(friendCode, json.dump());
}

int Connector::RemoveFriend(const std::string& friendCode)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->RemoveFriend(friendCode);
}
int Connector::AcceptFriend(const std::string& friendCode)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->AcceptFriend(friendCode);
}

int Connector::SetFriendInfo(const std::string& friendCode, ElaphantContact::HumanInfo::Item item, const std::string& value)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->SetFriendInfo(friendCode, item, value);
}

int Connector::GetFriendInfo(const std::string& friendCode, std::shared_ptr<ElaphantContact::FriendInfo>& friendInfo)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not Created!\n");
        return -1;
    }

    return mPeerNode->GetFriendInfo(friendCode, friendInfo);
}

ElaphantContact::Status Connector::GetStatus()
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return ElaphantContact::Status::Invalid;
    }

    return mPeerNode->GetStatus();
}

ElaphantContact::Status Connector::GetFriendStatus(const std::string& friendCode)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return ElaphantContact::Status::Invalid;
    }

    return mPeerNode->GetFriendStatus(friendCode);

}

std::shared_ptr<ElaphantContact::UserInfo> Connector::GetUserInfo()
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return std::shared_ptr<ElaphantContact::UserInfo>();
    }

    return mPeerNode->GetUserInfo();
}

int Connector::GetUserBrief(std::string& brief)
{
    if (mPeerNode.get() == nullptr) {
        printf("mPeerNode not Created!\n");
        return -1;
    }

    return mPeerNode->GetUserBrief(brief);
}

std::vector<std::shared_ptr<ElaphantContact::FriendInfo>> Connector::ListFriendInfo()
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return std::vector<std::shared_ptr<ElaphantContact::FriendInfo>>();
    }

    return mPeerNode->ListFriendInfo();
}

int Connector::SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& message)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    bool isDid = friendCode.at(0) == 'i' && isAddressValid(friendCode.c_str());

    std::string data;
    if (isDid) {
        Json json;
        json["serviceName"] = mServiceName;
        json["content"] = message;
        data = json.dump();
    }
    else {
        data = message;
    }

    return mPeerNode->SendMessage(friendCode, channel, data);
}

int Connector::SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::vector<uint8_t>& binary)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    bool isDid = friendCode.at(0) == 'i' && isAddressValid(friendCode.c_str());

    std::vector<uint8_t> data;
    if (isDid) {
        Json json;
        json["serviceName"] = mServiceName;
        json["content"] = "bianry";
        std::string jsonStr = json.dump();
        std::vector<uint8_t> bytes(jsonStr.begin(), jsonStr.end());
        data.insert(data.end(), bytes.begin(), bytes.end());
        data.insert(data.end(), PROTOCOL_APPEND_DATA.begin(), PROTOCOL_APPEND_DATA.end());
        data.insert(data.end(), binary.begin(), binary.end());
    }
    else {
        data = binary;
    }

    return mPeerNode->SendMessage(friendCode, channel, data);
}


}
