
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
        std::shared_ptr<PeerListener::MessageListener> listener = FindListener(requestEvent->summary);
        if (listener.get() != nullptr) {
            listener->onEvent(event);
        }
        break;
    }
    default:
    {
        std::unique_lock<std::mutex> _lock(mNode->mMsgListenerMutex);
        for (auto const& listener : mNode->mMsgListenerMap) {
            listener.second->onEvent(event);
        }
        break;
    }

    }

}

void PeerNode::ContactListener::onReceivedMessage(const std::string& humanCode,
                        ContactChannel channelType,
                        std::shared_ptr<ElaphantContact::Message> msgInfo)
{
    if (msgInfo->type == ElaphantContact::Message::Type::MsgText) {
        std::shared_ptr<PeerListener::MessageListener> listener = FindListener(msgInfo->data->toString());
        if (listener.get() != nullptr) {
            listener->onReceivedMessage(humanCode, channelType, msgInfo);
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

std::shared_ptr<PeerListener::MessageListener> PeerNode::ContactListener::FindListener(const std::string& content)
{
    std::unique_lock<std::mutex> _lock(mNode->mMsgListenerMutex);
    try {
        Json json = Json::parse(content);
        std::string name = toLower(json["serviceName"]);
        auto listener = mNode->mMsgListenerMap.find(name);
        if (listener != mNode->mMsgListenerMap.end()) {
            return listener->second;
        }
    } catch (const std::exception& e) {
        printf("parse json failed\n");
    }

    auto im = mNode->mMsgListenerMap.find("elaphantchat");
    if (im != mNode->mMsgListenerMap.end()) {
        return im->second;
    }

    return nullptr;
}

/*************************** PeerNode::ContactDataListener ***************************/
void PeerNode::ContactDataListener::onNotify(const std::string& humanCode,
                        ContactChannel channelType,
                        const std::string& dataId, int status)
{
    if (mNode->mDataListenerMap.empty()) return;
}

int PeerNode::ContactDataListener::onReadData(const std::string& humanCode,
                        ContactChannel channelType,
                        const std::string& dataId, uint64_t offset,
                        std::vector<uint8_t>& data)
{
    if (mNode->mDataListenerMap.empty()) return -1;
    return 0;
}

int PeerNode::ContactDataListener::onWriteData(const std::string& humanCode,
                        ContactChannel channelType,
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
    mContact->setListener(mContactListener.get());
    mContact->setDataListener(mContactDataListener.get());
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
    mMsgListenerMap[serviceName] = listener;
}

void PeerNode::RemoveMessageListener(const std::string& serviceName)
{
    std::unique_lock<std::mutex> _lock(mMsgListenerMutex);
    std::string name = toLower(serviceName);
    mMsgListenerMap.erase(name);
}

void PeerNode::AddDataListener(const std::string& serviceName, std::shared_ptr<PeerListener::DataListener>& listener)
{
    std::unique_lock<std::mutex> _lock(mDataListenerMutex);
    std::string name = toLower(serviceName);
    mDataListenerMap[serviceName] = listener;
}

void PeerNode::RemoveDataListener(const std::string& serviceName)
{
    std::unique_lock<std::mutex> _lock(mDataListenerMutex);
    std::string name = toLower(serviceName);
    mDataListenerMap.erase(name);
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

int PeerNode::SetUserInfo(int item, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    std::string did = GetDid();
    return mContact->setHumanInfo(did, item, value.c_str());
}

int PeerNode::SetIdentifyCode(int type, const std::string& value)
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

int PeerNode::GetFriendList(std::stringstream* info)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->getFriendList(info);
}

int PeerNode::SetFriendInfo(const std::string& friendCode, int item, const std::string& value)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->setHumanInfo(friendCode, item, value);
}

int PeerNode::PullData(const std::string& humanCode, int chType, const std::string& devId, const std::string& dataId)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    return mContact->pullData(humanCode.c_str(), chType, devId.c_str(), dataId.c_str());
}

int PeerNode::CancelPullData(const std::string& humanCode, int chType, const std::string& devId, const std::string& dataId)
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

int PeerNode::GetStatus()
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
    }

    std::string did = GetDid();
    return mContact->getHumanStatus(did.c_str());
}

int PeerNode::GetFriendStatus(const std::string& friendCode)
{
    if (mContact.get() == nullptr) {
        printf("ElaphantContact not Created!\n");
        return -1;
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

int PeerNode::SendMessage(const std::string& friendCode, const std::string& message)
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

    return mContact->sendMessage(friendCode.c_str(), ContactChannel::Carrier, msgInfo);
}

}
