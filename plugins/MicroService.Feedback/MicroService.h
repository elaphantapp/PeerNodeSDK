
#ifndef __ELASTOS_MICRO_SERVICE_H__
#define __ELASTOS_MICRO_SERVICE_H__

#include <memory>
#include <string>
#include "PeerListener.h"
#include "Connector.h"

namespace elastos {

class MicroService {
public:
    class MessageListener : public PeerListener::MessageListener {
    public:
        MessageListener(MicroService* outter)
            : mOutter(outter)
        {}

        virtual void onEvent(ElaphantContact::Listener::EventArgs& event) override;
        virtual void onReceivedMessage(const std::string& humanCode, ElaphantContact::Channel channelType,
                                   std::shared_ptr<ElaphantContact::Message> msgInfo) override;

    private:
        MicroService* mOutter;
    };

public:
    MicroService(const std::string& path)
        : mPath(path)
        , mName("feedback")
    {
        mConnector = std::make_shared<Connector>(mName);
        mListener = std::shared_ptr<PeerListener::MessageListener>(new MicroService::MessageListener(this));
        mConnector->SetMessageListener(mListener);
    }

    virtual ~MicroService() = default;

private:
    std::string mPath;
    std::string mName;
    std::shared_ptr<Connector> mConnector;
    std::shared_ptr<PeerListener::MessageListener> mListener;

};

}

#endif //__ELASTOS_MICRO_SERVICE_H__
