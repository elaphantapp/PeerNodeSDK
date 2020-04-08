#include "MS.ManagerListener.hpp"
#include "MS.ManagerCommand.hpp"
#include "Json.hpp"
#include "Utils/Log.hpp"

namespace elastos {
namespace MicroService {

ManagerListener::ManagerListener(std::weak_ptr<ManagerService> service)
    : mService(service)
{
}
ManagerListener::~ManagerListener()
{
    mService.reset();
}

void ManagerListener::onEvent(ElaphantContact::Listener::EventArgs& event)
{
    switch (event.type) {
    case ElaphantContact::Listener::EventType::StatusChanged:
    {
        auto statusEvent = dynamic_cast<ElaphantContact::Listener::StatusEvent*>(&event);
        Log::I(ManagerService::NAME, "Service %s received %s status changed %u\n",
                                     ManagerService::NAME, event.humanCode.c_str(), statusEvent->status);
        break;
    }
    case ElaphantContact::Listener::EventType::FriendRequest:
    {
        auto requestEvent = dynamic_cast<ElaphantContact::Listener::RequestEvent*>(&event);
        Log::I(ManagerService::NAME, "Service %s received %s friend request %s\n",
                                     ManagerService::NAME, event.humanCode.c_str(), requestEvent->summary.c_str());
        auto service = mService.lock();
        if (service.get() == nullptr) {
            Log::E(ManagerService::NAME, "Service has been destroyed. Ignore to process friend requeset.");
            break;
        }
        service->getConnector()->AcceptFriend(event.humanCode);
        break;
    }
    case ElaphantContact::Listener::EventType::HumanInfoChanged:
    {
        auto infoEvent = dynamic_cast<ElaphantContact::Listener::InfoEvent*>(&event);
        Log::I(ManagerService::NAME, "Service %s received %s info changed %s\n",
                                     ManagerService::NAME, event.humanCode.c_str(), infoEvent->toString().c_str());
        break;
    }
    default:
        Log::E(ManagerService::NAME, "Unprocessed event: %d", static_cast<int>(event.type));
        break;
    }
}

void ManagerListener::onReceivedMessage(const std::string& humanCode, ElaphantContact::Channel channelType,
                               std::shared_ptr<ElaphantContact::Message> msgInfo)
{
    Log::I(ManagerService::NAME, "Service %s received message from: %s, content: %s\n",
                                 ManagerService::NAME, humanCode.c_str(), msgInfo->data->toString().c_str());
    auto func = std::bind(&ManagerListener::onExecFinished, mService, std::placeholders::_1, std::placeholders::_2);
    ManagerCommand::DoAsync(humanCode, msgInfo->data->toString(), func);
}

void ManagerListener::onExecFinished(std::weak_ptr<ManagerService> weakService,
                                     const std::string& humanCode,
                                     const std::string& outMsg)
{
    Log::I(ManagerService::NAME, "Service %s exec finished for %s, content: %s\n",
                                 ManagerService::NAME, humanCode.c_str(), outMsg.c_str());

    auto service = weakService.lock();
    if (service.get() == nullptr) {
        Log::E(ManagerService::NAME, "Service has been destroyed. Ignore to response message.");
        return;
    }
    service->getConnector()->SendMessage(humanCode, ElaphantContact::Channel::Carrier, outMsg);
}

} // MicroService
} // elastos
