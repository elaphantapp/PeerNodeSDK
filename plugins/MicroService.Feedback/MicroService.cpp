
#include "MicroService.h"
#include "Json.hpp"

namespace elastos {

extern "C" {

void* CreateService(const char* path)
{
    MicroService* service = new MicroService(path);
    return static_cast<void *>(service);
}

void DestroyService(void* service)
{
    if (service != nullptr) {
        MicroService* instance = static_cast<MicroService *>(service);
        delete instance;
    }
}

}

void MicroService::MessageListener::onEvent(ElaphantContact::Listener::EventArgs& event)
{
    switch (event.type) {
    case ElaphantContact::Listener::EventType::StatusChanged:
    {
        auto statusEvent = dynamic_cast<ElaphantContact::Listener::StatusEvent*>(&event);
        printf("Serice %s received %s status changed %hhu\n", mOutter->mName.c_str(), event.humanCode.c_str(), statusEvent->status);
        break;
    }
    case ElaphantContact::Listener::EventType::FriendRequest:
    {
        auto requestEvent = dynamic_cast<ElaphantContact::Listener::RequestEvent*>(&event);
        printf("Serice %s received %s friend request %s\n", mOutter->mName.c_str(), event.humanCode.c_str(), requestEvent->summary.c_str());
        mOutter->mConnector->AcceptFriend(event.humanCode);
        break;
    }
    case ElaphantContact::Listener::EventType::HumanInfoChanged:
    {
        auto infoEvent = dynamic_cast<ElaphantContact::Listener::InfoEvent*>(&event);
        std::string content = infoEvent->toString();
        printf("Serice %s received %s info changed %s\n", mOutter->mName.c_str(), event.humanCode.c_str(), content.c_str());
        break;
    }
    default:
        printf("Unprocessed event: %d", static_cast<int>(event.type));
        break;
    }
}

void MicroService::MessageListener::onReceivedMessage(const std::string& humanCode,
                ElaphantContact::Channel channelType, std::shared_ptr<ElaphantContact::Message> msgInfo)
{
    printf("Serice %s received message from %s content %s\n", mOutter->mName.c_str(),
                        humanCode.c_str(), msgInfo->data->toString().c_str());

    mOutter->mConnector->SendMessage(humanCode, ElaphantContact::Channel::Carrier, msgInfo->data->toString());
}

}
