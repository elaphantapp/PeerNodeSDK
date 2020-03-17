
#ifndef __ELASTOS_CONNECTOR_H__
#define __ELASTOS_CONNECTOR_H__

#include <string>
#include <memory>
#include "PeerListener.h"
#include "PeerNode.h"
#include "HumanInfo.hpp"
#include "Contact.hpp"

namespace elastos {

class Connector {
public:
    Connector(const std::string& serviceName);

    ~Connector();

    void SetMessageListener(std::shared_ptr<PeerListener::MessageListener>& listener);

    void SetDataListener(std::shared_ptr<PeerListener::DataListener>& listener);

    int AddFriend(const std::string& friendCode, const std::string& summary);
    int RemoveFriend(const std::string& friendCode);
    int AcceptFriend(const std::string& friendCode);
    int SetFriendInfo(const std::string& friendCode, ElaphantContact::HumanInfo::Item item, const std::string& value);
    int GetFriendInfo(const std::string& friendCode, std::shared_ptr<ElaphantContact::FriendInfo>& friendInfo);

    ElaphantContact::Status GetStatus();
    ElaphantContact::Status GetFriendStatus(const std::string& friendCode);

    std::shared_ptr<ElaphantContact::UserInfo> GetUserInfo();
    int GetUserBrief(std::string& brief);
    std::vector<std::shared_ptr<ElaphantContact::FriendInfo>> ListFriendInfo();

    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& message);
    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::vector<uint8_t>& binary);

private:
    void RemoveMessageListener();
    void RemoveDataListener();

    std::string GetMemo(const std::string& friendCode);

private:
    std::string mServiceName;

    std::shared_ptr<PeerNode> mPeerNode;
    std::shared_ptr<PeerListener::MessageListener> mMessageListener;
    std::shared_ptr<PeerListener::DataListener> mDataListener;
};

}

#endif //__ELASTOS_CONNECTOR_H__
