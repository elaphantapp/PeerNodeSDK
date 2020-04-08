#ifndef __ELASTOS_MS_MANAGER_SERVICE_H__
#define __ELASTOS_MS_MANAGER_SERVICE_H__

#include <Connector.h>

namespace elastos {
namespace MicroService {

extern "C" void* CreateService(const char* path);
extern "C" void DestroyService(void* service);

class ManagerService : public std::enable_shared_from_this<ManagerService>
{
public:
    static constexpr const char* NAME = "ManagerService";

    explicit ManagerService() = default;
    virtual ~ManagerService() = default;

    void init(const std::string& path);
    std::shared_ptr<Connector> getConnector();

private:
    static std::shared_ptr<ManagerService> sInstance;

    std::string mPath;
    std::shared_ptr<Connector> mConnector;

    friend void* CreateService(const char* path);
    friend void DestroyService(void* service);
};

} // MicroService
} // elastos

#endif //__ELASTOS_MS_MANAGER_SERVICE_H__
