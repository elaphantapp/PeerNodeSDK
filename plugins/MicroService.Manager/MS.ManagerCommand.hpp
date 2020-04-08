#ifndef __ELASTOS_MS_MANAGER_COMMAND_H__
#define __ELASTOS_MS_MANAGER_COMMAND_H__

#include <functional>
#include <memory>
#include <string>
#include <vector>
#include <Utils/ThreadPool.hpp>

namespace elastos {
namespace MicroService {

class ManagerCommand {
public:
    /*** type define ***/

    /*** static function and variable ***/
    static void DoAsync(const std::string& humanCode,
                        const std::string& cmdLine,
                        const std::function<void(const std::string&,const std::string&)> onFinished);
    static int Do(const std::string& humanCode,
                  const std::string& cmdLine,
                  std::string& outMsg, std::string& errMsg);

    /*** class function and variable ***/

protected:
    /*** type define ***/

    /*** static function and variable ***/

    /*** class function and variable ***/

private:
    /*** type define ***/
    struct CommandInfo {
        char mCmd;
        std::string mLongCmd;
        std::function<int(const std::string& humanCode, const std::vector<std::string>&, std::string&, std::string&)> mFunc;
        std::string mUsage;
    };

    /*** static function and variable ***/
    static int Help(const std::string& humanCode,
                    const std::vector<std::string>& args,
                    std::string& outMsg, std::string& errMsg);
    static int CreateMicroService(const std::string& humanCode,
                                  const std::vector<std::string>& args,
                                  std::string& outMsg, std::string& errMsg);
    static int StartMicroService(const std::string& humanCode,
                                 const std::vector<std::string>& args,
                                 std::string& outMsg, std::string& errMsg);

    static ThreadPool gProcessThread;
    static const std::vector<CommandInfo> gCmdInfoList;

    /*** class function and variable ***/
    explicit ManagerCommand() = delete;
    virtual ~ManagerCommand() = delete;
};
/***********************************************/
/***** class template function implement *******/
/***********************************************/

/***********************************************/
/***** macro definition ************************/
/***********************************************/

} // MicroService
} // elastos

#endif /* __ELASTOS_MS_MANAGER_COMMAND_H__ */

