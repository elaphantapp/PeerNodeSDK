
#include "PeerNode.h"
#include "Json.hpp"

namespace elastos {

std::shared_ptr<PeerNode> PeerNode::sInstance;

static std::string toLower(const std::string& str)
{
    std::string ret(str.size(), 'a');
    std::transform(str.begin(), str.end(), ret.begin(),
                [](unsigned char c){ return std::tolower(c); });
    return ret;
}

/*************************** PeerNode::ContactListener ***************************/
std::shared_ptr<std::vector<uint8_t>> PeerNode::ContactListener::onAcquire(const ContactListener::AcquireArgs& request)
{
    if (mNode->mListener.get() == nullptr) {
        return std::shared_ptr<std::vector<uint8_t>>();
    }

    std::shared_ptr<PeerListener::Listener> listener;
    {
        std::unique_lock<std::mutex> _lock(mNode->mListenerMutex);
        listener = mNode->mListener;
    }

    return listener->onAcquire(request);
}

void PeerNode::ContactListener::onEvent(ContactListener::EventArgs& event)
{
    if (mNode->mMsgListenerMap.empty()) return;

    switch (event.type) {
    case ElaphantContact::Listener::EventType::FriendRequest:
    {
        auto requestEvent = dynamic_cast<ElaphantContact::Listener::RequestEvent*>(&event);
        std::string content;
        auto listeners = FindListener(requestEvent->summary, content);
        if (listeners.size() == 0) return;

        requestEvent->summary = content;
        for (auto const& listener : listeners) {
            listener->onEvent(event);
        }
        break;
    }
    default:
    {
        std::unique_lock<std::mutex> _lock(mNode->mMsgListenerMutex);
        for (auto const& listeners : mNode->mMsgListenerMap) {
            for (auto const& listener : listeners.second) {
                listener->onEvent(event);
            }
        }
        break;
    }

    }

}

void PeerNode::ContactListener::onReceivedMessage(const std::string& humanCode,
                        ElaphantContact::Channel channelType,
                        std::shared_ptr<ElaphantContact::Message> msgInfo)
{
    if (msgInfo->type == ElaphantContact::Message::Type::MsgText) {
        std::string content;
        auto listeners = FindListener(msgInfo->data->toString(), content);
        if (listeners.size() == 0) return;
        for (auto const& listener : listeners) {
            listener->onReceivedMessage(humanCode, channelType, ElaphantContact::MakeTextMessage(content));
        }

    }
    else if (msgInfo->type == ElaphantContact::Message::Type::MsgBinary) {
        std::vector<uint8_t> data = msgInfo->data->toData();
        auto it = std::find(data.begin(), data.end(), 0);

        if (it != data.end()) {
            int index = distance(data.begin(), it);
            std::vector<uint8_t> protocol(data.begin(), data.begin() + index);
            std::vector<uint8_t> binary(data.begin() + index + 1, data.end());
            std::string jsonStr(protocol.begin(), protocol.end());

            try {
                Json json = Json::parse(jsonStr);
                std::string content;
                auto listeners = FindListener(jsonStr, content);
                if (listeners.size() == 0) return;
                for (auto const& listener : listeners) {
                    listener->onReceivedMessage(humanCode, channelType, ElaphantContact::MakeBinaryMessage(binary));
                }
                return;
            } catch (const std::exception& e) {
                printf("parse json failed: %s\n", jsonStr.c_str());
            }
        }

        std::unique_lock<std::mutex> _lock(mNode->mMsgListenerMutex);
        auto ims = mNode->mMsgListenerMap.find(CHAT_SERVICE_NAME);
        if (ims != mNode->mMsgListenerMap.end()) {
            for (auto const& listener : ims->second) {
                listener->onReceivedMessage(humanCode, channelType, ElaphantContact::MakeBinaryMessage(data));
            }
        }
    }
}

void PeerNode::ContactListener::onError(int errCode, const std::string& errStr, const std::string& ext)
{
    if (mNode->mListener.get() == nullptr) {
        return;
    }

    std::shared_ptr<PeerListener::Listener> listener;
    {
        std::unique_lock<std::mutex> _lock(mNode->mListenerMutex);
        listener = mNode->mListener;
    }

    return listener->onError(errCode, errStr, ext);
}

std::vector<std::shared_ptr<PeerListener::MessageListener>> PeerNode::ContactListener::FindListener(
            const std::string& content, std::string& out)
{
    std::unique_lock<std::mutex> _lock(mNode->mMsgListenerMutex);

    try {
        Json json = Json::parse(content);
        std::string name = toLower(json["serviceName"]);
        out = json["content"];
        auto listeners = mNode->mMsgListenerMap.find(name);

        if (listeners != mNode->mMsgListenerMap.end()) {
            return listeners->second;
        }
    } catch (const std::exception& e) {
        printf("parse json failed: %s\n", content.c_str());
        out = content;
    }

    auto ims = mNode->mMsgListenerMap.find(CHAT_SERVICE_NAME);
    if (ims != mNode->mMsgListenerMap.end()) {
        return ims->second;
    }

    return std::vector<std::shared_ptr<PeerListener::MessageListener>>();
}

/*************************** PeerNode::ContactDataListener ***************************/
void PeerNode::ContactDataListener::onNotify(const std::string& humanCode,
                        ElaphantContact::Channel channelType,
                        const std::string& dataId, int status)
{
    if (mNode->mDataListenerMap.empty()) return;
}

int PeerNode::ContactDataListener::onReadData(const std::string& humanCode,
                        ElaphantContact::Channel channelType,
                        const std::string& dataId, uint64_t offset,
                        std::vector<uint8_t>& data)
{
    if (mNode->mDataListenerMap.empty()) return -1;
    return 0;
}

int PeerNode::ContactDataListener::onWriteData(const std::string& humanCode,
                        ElaphantContact::Channel channelType,
                        const std::string& dataId, uint64_t offset,
                        const std::vector<uint8_t>& data)
{
    if (mNode->mDataListenerMap.empty()) return -1;
    return 0;
}

/*************************** PeerNode ***************************/
std::shared_ptr<PeerNode> PeerNode::GetInstance(const std::string& path)
{
    if (path.empty()) {
        return nullptr;
    }

    if (sInstance.get() == nullptr) {
        sInstance = std::shared_ptr<PeerNode>(new PeerNode(path));
    }

    return sInstance;
}

std::shared_ptr<PeerNode> PeerNode::GetInstance()
{
    return sInstance;
}

PeerNode::PeerNode(const std::string& path)
{
    ElaphantContact::Factory::SetLogLevel(7);
    ElaphantContact::Factory::SetLocalDataDir(path);

    mContact = ElaphantContact::Factory::Create();
    if (mContact.get() == nullptr) {
        printf("ElaphantContact Factory Create failed!\n");
        return;
    }

    mContactListener = std::make_shared<PeerNode::ContactListener>(this);
    mContactDataListener = std::make_shared<PeerNode::ContactDataListener>(this);
    mContact->setListener(mContactListener);
    mContact->setDataListener(mContactDataListener);
}

std::string PeerNode::GetDid()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return "";
    }

    auto userInfo = mContact->getUserInfo();
    if (userInfo == nullptr) {
        printf("getUserInfo failed!\n");
        return "";
    }

    std::string humanCode;
    userInfo->getHumanCode(humanCode);

    return humanCode;
}

void PeerNode::SetListener(std::shared_ptr<PeerListener::Listener>& listener)
{
    std::unique_lock<std::mutex> _lock(mListenerMutex);
    mListener = listener;
}

void PeerNode::AddMessageListener(const std::string& serviceName, std::shared_ptr<PeerListener::MessageListener>& listener)
{
    std::unique_lock<std::mutex> _lock(mMsgListenerMutex);
    std::string name = toLower(serviceName);

    auto search = mMsgListenerMap.find(name);
    if (search != mMsgListenerMap.end()) {
        mMsgListenerMap[name].push_back(listener);
    }
    else {
        std::vector<std::shared_ptr<PeerListener::MessageListener>> v;
        v.push_back(listener);
        mMsgListenerMap[name] = v;
    }
}

void PeerNode::RemoveMessageListener(const std::string& serviceName, std::shared_ptr<PeerListener::MessageListener>& listener)
{
    std::unique_lock<std::mutex> _lock(mMsgListenerMutex);
    std::string name = toLower(serviceName);

    auto search = mMsgListenerMap.find(name);
    if (search == mMsgListenerMap.end()) return;

    std::vector<std::shared_ptr<PeerListener::MessageListener>>& v = mMsgListenerMap[name];

    for (auto it = v.begin(); it != v.end(); it++) {
        if (*it == listener) {
            v.erase(it);
            break;
        }
    }

    if (v.size() == 0) {
        mMsgListenerMap.erase(name);
    }
}

void PeerNode::AddDataListener(const std::string& serviceName, std::shared_ptr<PeerListener::DataListener>& listener)
{
    std::unique_lock<std::mutex> _lock(mDataListenerMutex);
    std::string name = toLower(serviceName);

    auto search = mDataListenerMap.find(name);
    if (search != mDataListenerMap.end()) {
        mDataListenerMap[name].push_back(listener);
    }
    else {
        std::vector<std::shared_ptr<PeerListener::DataListener>> v;
        v.push_back(listener);
        mDataListenerMap[name] = v;
    }
}

void PeerNode::RemoveDataListener(const std::string& serviceName, std::shared_ptr<PeerListener::DataListener>& listener)
{
    std::unique_lock<std::mutex> _lock(mDataListenerMutex);
    std::string name = toLower(serviceName);

    auto search = mDataListenerMap.find(name);
    if (search == mDataListenerMap.end()) return;

    std::vector<std::shared_ptr<PeerListener::DataListener>>& v = mDataListenerMap[name];

    for (auto it = v.begin(); it != v.end(); it++) {
        if (*it == listener) {
            v.erase(it);
            break;
        }
    }

    if (v.size() == 0) {
        mDataListenerMap.erase(name);
    }
}

int PeerNode::Start()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->start();
}

int PeerNode::Stop()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->stop();
}

int PeerNode::AppendChannelStrategy(crosspl::native::ChannelStrategyPtr channelStrategy)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->appendChannelStrategy(channelStrategy);
}

int PeerNode::SetUserInfo(ElaphantContact::HumanInfo::Item item, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    std::string did = GetDid();
    return mContact->setHumanInfo(did, item, value.c_str());
}

int PeerNode::SetIdentifyCode(ElaphantContact::UserInfo::Type type, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->setIdentifyCode(type, value.c_str())   ;
}

int PeerNode::AddFriend(const std::string& friendCode, const std::string& summary)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->addFriend(friendCode, summary);
}

int PeerNode::RemoveFriend(const std::string& friendCode)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->removeFriend(friendCode);
}

int PeerNode::AcceptFriend(const std::string& friendCode)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->acceptFriend(friendCode);
}

int PeerNode::SetFriendInfo(const std::string& friendCode, ElaphantContact::HumanInfo::Item item, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->setHumanInfo(friendCode, item, value);
}

int PeerNode::GetFriendInfo(const std::string& friendCode, std::shared_ptr<ElaphantContact::FriendInfo>& friendInfo)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    std::shared_ptr<ElaphantContact::HumanInfo> humanInfo;
    int ret = mContact->getHumanInfo(friendCode, humanInfo);
    if (ret == 0) {
        friendInfo = std::dynamic_pointer_cast<ElaphantContact::FriendInfo>(humanInfo);
    }
    return ret;
}

int PeerNode::PullData(const std::string& humanCode, ElaphantContact::Channel chType, const std::string& devId, const std::string& dataId)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->pullData(humanCode.c_str(), chType, devId.c_str(), dataId.c_str());
}

int PeerNode::CancelPullData(const std::string& humanCode, ElaphantContact::Channel chType, const std::string& devId, const std::string& dataId)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->cancelPullData(humanCode.c_str(), chType, devId.c_str(), dataId.c_str());
}

int PeerNode::SyncInfoDownloadFromDidChain()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->syncInfoDownloadFromDidChain();
}


int PeerNode::SyncInfoUploadToDidChain()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->syncInfoUploadToDidChain();
}

int PeerNode::SetWalletAddress(const std::string& name, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->setWalletAddress(name.c_str(), value.c_str());
}

ElaphantContact::Status PeerNode::GetStatus()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return ElaphantContact::Status::Invalid;
    }

    std::string did = GetDid();
    return mContact->getHumanStatus(did.c_str());
}

ElaphantContact::Status PeerNode::GetFriendStatus(const std::string& friendCode)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return ElaphantContact::Status::Invalid;
    }

    return mContact->getHumanStatus(friendCode.c_str());
}

std::shared_ptr<ElaphantContact::UserInfo> PeerNode::GetUserInfo()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return std::shared_ptr<ElaphantContact::UserInfo>();
    }

    return mContact->getUserInfo();
}

std::vector<std::shared_ptr<ElaphantContact::FriendInfo>> PeerNode::ListFriendInfo()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return std::vector<std::shared_ptr<ElaphantContact::FriendInfo>>();
    }

    return mContact->listFriendInfo();
}

int PeerNode::SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::string& message)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    auto msgInfo = ElaphantContact::MakeTextMessage(message);
    if(msgInfo == nullptr) {
        printf("Failed to make text message.");
        return -1;
    }

    return mContact->sendMessage(friendCode.c_str(), channel, msgInfo);
}

int PeerNode::SendMessage(const std::string& friendCode, ElaphantContact::Channel channel, const std::vector<uint8_t>& binary)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    auto msgInfo = ElaphantContact::MakeBinaryMessage(binary);
    if(msgInfo == nullptr) {
        printf("Failed to make binary message.");
        return -1;
    }

    return mContact->sendMessage(friendCode.c_str(), channel, msgInfo);
}

int PeerNode::ExportUserData(const std::string& toFile)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->exportUserData(toFile);
}

int PeerNode::ImportUserData(const std::string& fromFile)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->importUserData(fromFile);
}

}
