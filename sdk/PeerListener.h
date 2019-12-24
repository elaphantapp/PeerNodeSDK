
#ifndef __ELASTOS_PEER_LISTENER_H__
#define __ELASTOS_PEER_LISTENER_H__

#include <memory>
#include <string>
#include "ContactListener.hpp"
#include "Contact.hpp"

namespace elastos {

class PeerListener {

public:
    class Listener {
    public:
        virtual std::shared_ptr<std::vector<uint8_t>> onAcquire(const ElaphantContact::Listener::AcquireArgs& request) = 0;
        virtual void onError(int errCode, const std::string& errStr, const std::string& ext) = 0;
    };

    class MessageListener {
    public:
        virtual void onEvent(ElaphantContact::Listener::EventArgs& event) = 0;
        virtual void onReceivedMessage(const std::string& humanCode, ElaphantContact::Channel channelType,
                                   std::shared_ptr<ElaphantContact::Message> msgInfo) = 0;
    };

    class DataListener {
    public:
        virtual void onNotify(const std::string& humanCode, ElaphantContact::Channel channelType,
                                const std::string& dataId, int status) = 0;
        virtual int onReadData(const std::string& humanCode, ElaphantContact::Channel channelType,
                                const std::string& dataId, uint64_t offset,
                                std::vector<uint8_t>& data) = 0;
        virtual int onWriteData(const std::string& humanCode, ElaphantContact::Channel channelType,
                                const std::string& dataId, uint64_t offset,
                                const std::vector<uint8_t>& data) = 0;
    };

};

}

#endif // __ELASTOS_PEER_LISTENER_H__
