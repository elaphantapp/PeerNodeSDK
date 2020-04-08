#include "MS.ManagerCommand.hpp"

#include <iostream>
#include <iterator>
#include <sstream>
#include <Json.hpp>

namespace elastos {
namespace MicroService {

/* =========================================== */
/* === variables initialize =========== */
/* =========================================== */
ThreadPool ManagerCommand::gProcessThread { "mgr-cmd-processor" };
const std::vector <ManagerCommand::CommandInfo> ManagerCommand::gCmdInfoList{
        {'h', "help",   ManagerCommand::Help,               "/h: Print help usages."},
        {'c', "create", ManagerCommand::CreateMicroService, "/c [servicename]: create service."},
        {'s', "start",  ManagerCommand::StartMicroService,  "/s [servicename]: start service."},
};
    
inline std::string trim(const std::string &s)
{
    auto wsfront=std::find_if_not(s.begin(),s.end(),[](int c){return std::isspace(c);});
    auto wsback=std::find_if_not(s.rbegin(),s.rend(),[](int c){return std::isspace(c);}).base();
    return (wsback<=wsfront ? std::string() : std::string(wsfront,wsback));
}
/* =========================================== */
/* === function implement ============= */
/* =========================================== */
void ManagerCommand::DoAsync(const std::string& humanCode,
                             const std::string& cmdLine,
                             const std::function<void(const std::string&,const std::string&)> onFinished)
{
    gProcessThread.post([=]() {
        std::string outMsg, errMsg;
        int ret = ManagerCommand::Do(humanCode, cmdLine, outMsg, errMsg);

        Json json;
        json["command"] = cmdLine;
        json["result"] = ret;
        json["content"] = outMsg;
        json["desc"] = errMsg;

        onFinished(humanCode, json.dump());
    });
}

int ManagerCommand::Do(const std::string& humanCode,
                       const std::string &cmdLine,
                       std::string &outMsg, std::string& errMsg)
{
    auto wsfront=std::find_if_not(cmdLine.begin(), cmdLine.end(),
                                 [](int c){return std::isspace(c);});
    auto wsback=std::find_if_not(cmdLine.rbegin(), cmdLine.rend(),
                                 [](int c){return std::isspace(c);}).base();
    auto trimCmdLine = (wsback <= wsfront ? std::string() : std::string(wsfront, wsback));
    if (trimCmdLine.find('/') != 0) {
        outMsg = "Bad command";
        return -1;
    }

    std::istringstream iss(trimCmdLine);
    std::vector<std::string> args {std::istream_iterator<std::string>{iss},
                                   std::istream_iterator<std::string>{}};
    if (args.size() <= 0) {
        return 0;
    }
    const auto& cmd = args[0];

    for(const auto& cmdInfo : gCmdInfoList) {
        if(cmdInfo.mCmd == ' '
        || cmdInfo.mFunc == nullptr) {
            continue;
        }
        if(cmd.compare(1, 1, &cmdInfo.mCmd) != 0
        && cmd != cmdInfo.mLongCmd) {
            continue;
        }

        int ret = cmdInfo.mFunc(humanCode, args, outMsg, errMsg);
        return ret;
    }

    outMsg = "Unknown command: " + cmd;
    return -1;
}

/* =========================================== */
/* === class public function implement  ====== */
/* =========================================== */

/* =========================================== */
/* === class protected function implement  === */
/* =========================================== */


/* =========================================== */
/* === class private function implement  ===== */
/* =========================================== */
int ManagerCommand::Help(const std::string& humanCode,
                         const std::vector <std::string> &args,
                         std::string &outMsg, std::string& errMsg)
{
    std::stringstream ssMsg;
    for (const auto& cmdInfo : gCmdInfoList) {
        ssMsg << cmdInfo.mCmd << " | "
              << cmdInfo.mLongCmd << " : "
              << cmdInfo.mUsage << "\n";
    }

    outMsg = ssMsg.str();
    return 0;
}

int ManagerCommand::CreateMicroService(const std::string& humanCode,
                                       const std::vector <std::string> &args,
                                       std::string &outMsg, std::string& errMsg)
{
    return -1;
}

int ManagerCommand::StartMicroService(const std::string& humanCode,
                                      const std::vector <std::string> &args,
                                      std::string &outMsg, std::string& errMsg)
{
    return -1;
}

} // MicroService
} // elastos
