
#include "ConnectorTest.h"

void ConnectorTest::MessageListener::onEvent(ContactListener::EventArgs& event)
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

void ConnectorTest::MessageListener::onReceivedMessage(const std::string& humanCode,
                ContactChannel channelType, std::shared_ptr<ElaphantContact::Message> msgInfo)
{
    printf("Serice %s received message from %s content %s\n", mOutter->mName.c_str(),
                        humanCode.c_str(), msgInfo->data->toString().c_str());

    std::stringstream ss;
    ss << "{\"serviceName\":\"" << mOutter->mName << "\",\"content\":\"hello\"}";
    mOutter->mConnector->SendMessage(humanCode, ss.str());
}

ConnectorTest::ConnectorTest(const std::string& name)
    : mName(name)
{
    mConnector = std::make_shared<elastos::Connector>(name);
    mListener = std::shared_ptr<elastos::PeerListener::MessageListener>(new ConnectorTest::MessageListener(this));
    mConnector->SetMessageListener(mListener);
}


