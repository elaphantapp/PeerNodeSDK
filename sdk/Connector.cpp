
#include "Connector.h"

namespace elastos {

Connector::Connector(const std::string& serviceName)
    : mServiceName(serviceName)
{
    mPeerNode = PeerNode::GetInstance();
}

Connector::~Connector()
{
    if (mPeerNode.get() != nullptr) {
        mPeerNode->RemoveMessageListener(mServiceName);
        mPeerNode->RemoveDataListener(mServiceName);
    }
}

void Connector::SetMessageListener(std::shared_ptr<PeerListener::MessageListener>& listener)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return;
    }

    mPeerNode->AddMessageListener(mServiceName, listener);
}

void Connector::SetDataListener(std::shared_ptr<PeerListener::DataListener>& listener)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return;
    }

    mPeerNode->AddDataListener(mServiceName, listener);
}

int Connector::AddFriend(const std::string& friendCode, const std::string& summary)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->AddFriend(friendCode, summary);
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

int Connector::GetFriendList(std::stringstream* info)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->GetFriendList(info);
}

int Connector::SetFriendInfo(const std::string& friendCode, int item, const std::string& value)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->SetFriendInfo(friendCode, item, value);
}

int Connector::GetStatus()
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->GetStatus();
}

int Connector::GetFriendStatus(const std::string& friendCode)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
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

std::vector<std::shared_ptr<ElaphantContact::FriendInfo>> Connector::ListFriendInfo()
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return std::vector<std::shared_ptr<ElaphantContact::FriendInfo>>();
    }

    return mPeerNode->ListFriendInfo();
}

int Connector::SendMessage(const std::string& friendCode, const std::string& message)
{
    if (mPeerNode.get() == nullptr) {
        printf("PeerNode not created!\n");
        return -1;
    }

    return mPeerNode->SendMessage(friendCode, message);
}


}
