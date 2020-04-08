#include "MS.ManagerService.hpp"
#include "MS.ManagerListener.hpp"
#include "Json.hpp"
#include "Utils/Log.hpp"

namespace elastos {
namespace MicroService {

void* CreateService(const char* path)
{
    ManagerService::sInstance = std::make_shared<ManagerService>();
    Log::W(ManagerService::NAME, "CreateService %s@%p.", ManagerService::NAME, ManagerService::sInstance.get());
    ManagerService::sInstance->init(path);
    return static_cast<void *>(ManagerService::sInstance.get());
}

void DestroyService(void* service)
{
    Log::W(ManagerService::NAME, "DestroyService %s@%p.", ManagerService::NAME, service);
    if (service != ManagerService::sInstance.get()) {
        return;
    }

    ManagerService::sInstance.reset();
}

/****************************************************************/ 
/*  class ManagerService                                        */ 
/****************************************************************/ 

std::shared_ptr<ManagerService> ManagerService::sInstance;

void ManagerService::init(const std::string& path)
{
    mPath = path;
    mConnector = std::make_shared<Connector>(NAME);
    auto listener = std::make_shared<ManagerListener>(weak_from_this());
    auto castlistener = std::dynamic_pointer_cast<PeerListener::MessageListener>(listener);
    mConnector->SetMessageListener(castlistener);
}

std::shared_ptr<Connector> ManagerService::getConnector()
{
    return mConnector;
}

} // MicroService
} // elastos
