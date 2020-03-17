
#ifndef __ELASTOS_PEER_NODE_H__
#define __ELASTOS_PEER_NODE_H__

#include <string>
#include <memory>
#include "PeerListener.h"
#include "Contact.hpp"

#define CHAT_SERVICE_NAME   "chat"

namespace elastos {

class PeerNode {
private:
    class ContactListener : public ElaphantContact::Listener {
    public:
        explicit ContactListener(PeerNode* node)
            : mNode(node)
        {};

        virtual ~ContactListener() = default;

        virtual std::shared_ptr<std::vector<uint8_t>> onAcquire(const ElaphantContact::Listener::AcquireArgs& request) override;

        virtual void onEvent(ElaphantContact::Listener::EventArgs& event) override;

        virtual void onReceivedMessage(const std::string& humanCode,
                                       ElaphantContact::Channel channelType,
                                       std::shared_ptr<ElaphantContact::Message> msgInfo) override;

        virtual void onError(int errCode, const std::string& errStr,
                             const std::string& ext) override;
    private:
        std::vector<std::shared_ptr<PeerListener::MessageListener>> FindListener(const std::string& content, std::string& out);

        std::vector<std::shared_ptr<PeerListener::MessageListener>> FindListener(const std::string& memo);

    private:
        PeerNode* mNode;
    };

    class ContactDataListener : public ElaphantContact::DataListener {
    public:
        explicit ContactDataListener(PeerNode* node)
            : mNode(node)
        {};

        virtual ~ContactDataListener() = default;

        virtual void onNotify(const std::string& humanCode,
                              ElaphantContact::Channel channelType,
                              const std::string& dataId, int status) override;

        virtual int onReadData(const std::string& humanCode,
                               ElaphantContact::Channel channelType,
                               const std::string& dataId, uint64_t offset,
                               std::vector<uint8_t>& data) override;

        virtual int onWriteData(const std::string& humanCode,
                                ElaphantContact::Channel channelType,
                                const std::string& dataId, uint64_t offset,
                                const std::vector<uint8_t>& data) override;
    private:
        PeerNode* mNode;
    };

public:
    ~PeerNode()
    {
        mMsgListenerMap.clear();
        mDataListenerMap.clear();
    }

    void SetListener(std::shared_ptr<PeerListener::Listener>& listener);

    void AddMessageListener(const std::string& serviceName, std::shared_ptr<PeerListener::MessageListener>& listener);
    void RemoveMessageListener(const std::string& serviceName, std::shared_ptr<PeerListener::MessageListener>& listener);

    void AddDataListener(const std::string& serviceName, std::shared_ptr<PeerListener::DataListener>& listener);
    void RemoveDataListener(const std::string& serviceName, std::shared_ptr<PeerListener::DataListener>& listener);


    int Start();
    int Stop();

    int AppendChannelStrategy(crosspl::native::ChannelStrategyPtr channelStrategy);

    int SetUserInfo(ElaphantContact::HumanInfo::Item item, const std::string& value);
    int SetIdentifyCode(ElaphantContact::UserInfo::Type type, const std::string& value);

    int AddFriend(const std::string& friendCode, const std::string& summary);
    int RemoveFriend(const std::string& friendCode);
    int AcceptFriend(const std::string& friendCode);
    int SetFriendInfo(const std::string& friendCode, ElaphantContact::HumanInfo::Item item, const std::string& value);
    int GetFriendInfo(const std::string& friendCode, std::shared_ptr<ElaphantContact::FriendInfo>& friendInfo);


    int PullData(const std::string& humanCode, ElaphantContact::Channel chType, const std::string& devId, const std::string& dataId);
    int CancelPullData(const std::string& humanCode, ElaphantContact::Channel chType, const std::string& devId, const std::string& dataId);

    int SyncInfoDownloadFromDidChain();
    int SyncInfoUploadToDidChain();

    int SetWalletAddress(const std::string& name, const std::string& value);

    ElaphantContact::Status GetStatus();
    ElaphantContact::Status GetFriendStatus(const std::string& friendCode);

    std::shared_ptr<ElaphantContact::UserInfo> GetUserInfo();
    int GetUserBrief(std::string& brief);
    std::vector<std::shared_ptr<ElaphantContact::FriendInfo>> ListFriendInfo();

    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& message);
    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::vector<uint8_t>& binary);

    int ExportUserData(const std::string& toFile);
    int ImportUserData(const std::string& fromFile);

public:
    // create instance if sInstance is null.
    static std::shared_ptr<PeerNode> GetInstance(const std::string& path);
    //do not create instance, just return sInstance.
    static std::shared_ptr<PeerNode> GetInstance();

private:
    PeerNode(const std::string& path);

    std::string GetDid();

    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& memo, const std::string& message);
    int64_t SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& memo, const std::vector<uint8_t>& binary);

private:
    static std::shared_ptr<PeerNode> sInstance;

    std::shared_ptr<PeerListener::Listener> mListener;
    std::map<std::string, std::vector<std::shared_ptr<PeerListener::MessageListener>>> mMsgListenerMap;
    std::map<std::string, std::vector<std::shared_ptr<PeerListener::DataListener>>> mDataListenerMap;

    std::mutex mListenerMutex;
    std::mutex mMsgListenerMutex;
    std::mutex mDataListenerMutex;

    std::shared_ptr<ElaphantContact> mContact;
    std::shared_ptr<ElaphantContact::Listener> mContactListener;
    std::shared_ptr<ElaphantContact::DataListener> mContactDataListener;

    friend class Connector;
};

}

#endif // __ELASTOS_PEER_NODE_H__
