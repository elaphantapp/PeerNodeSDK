
#ifndef __CONNECTOR_TEST_H__
#define __CONNECTOR_TEST_H__

#include "Connector.h"
#include "PeerListener.h"

class ConnectorTest {
public:
    class MessageListener : public elastos::PeerListener::MessageListener {
    public:
        MessageListener(ConnectorTest* outter)
            : mOutter(outter)
        {}

        virtual void onEvent(ContactListener::EventArgs& event) override;
        virtual void onReceivedMessage(const std::string& humanCode, ContactChannel channelType,
                                   std::shared_ptr<ElaphantContact::Message> msgInfo) override;

    private:
        ConnectorTest* mOutter;
    };


public:
    ConnectorTest(const std::string& name);
    ~ConnectorTest()
    {}

    std::shared_ptr<elastos::Connector> mConnector;
private:
    std::shared_ptr<elastos::PeerListener::MessageListener> mListener;
    std::string mName;
};


#endif //__CONNECTOR_TEST_H__
