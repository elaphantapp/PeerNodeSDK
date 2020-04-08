#ifndef __ELASTOS_MS_MANAGER_LISTENER_H__
#define __ELASTOS_MS_MANAGER_LISTENER_H__

#include <PeerListener.h>
#include "MS.ManagerService.hpp"

namespace elastos {
namespace MicroService {

class ManagerListener : public PeerListener::MessageListener
                      , std::enable_shared_from_this<ManagerListener>
{
public:
    explicit ManagerListener(std::weak_ptr<ManagerService> service);
    virtual ~ManagerListener();

    virtual void onEvent(ElaphantContact::Listener::EventArgs& event) override;
    virtual void onReceivedMessage(const std::string& humanCode,
                                   ElaphantContact::Channel channelType,
                                   std::shared_ptr<ElaphantContact::Message> msgInfo) override;

private:
    static void onExecFinished(std::weak_ptr<ManagerService> weakService,
                               const std::string& humanCode,
                               const std::string& outMsg);

    std::weak_ptr<ManagerService> mService;
};

} // MicroService
} // elastos

#endif //__ELASTOS_MS_MANAGER_LISTENER_H__
