
#include <string>
#include <iostream>
#include <unistd.h>
#include <thread>
#include <chrono>
#include "PeerNode.h"
#include "ConnectorTest.h"
#include "Elastos.Wallet.Utility.h"

const char* c_help = \
    "s  start     create and start peer node.\n" \
    "c  conn      test connector.\n" \
    "t  thread    test connector in multi thread.\n" \
    "h  help      show help message.\n" \
    "e  exit      exit the test program.\n" \
    "\n";

const std::string mnemonic = "dove arctic cute sunset solution invest wasp lawn dawn town snake eight";
const std::string testPrivateKey = "fc930bfc48efaa0aedd245725ce3a3f16294c7c9c5f7219d741409d3d1c927d8";
const std::string testPublicKey = "0220f01b9a715acf02b3d45be2a29138be8f2f8c328da118c617ac11305cdf44fa";

void createAndStartPeerNode();
void createConnector();
void multiConnector();

std::shared_ptr<elastos::PeerNode> gPeerNode;
std::shared_ptr<ConnectorTest> gConnector;
std::vector<std::shared_ptr<ConnectorTest>> gConnectorVector;
std::vector<std::string> gServiceNameVector = {
    "ThreadTest1",
    "ThreadTest2",
    "ThreadTest3",
    "ThreadTest4",
    "ThreadTest5"
};

int main(int argc, char* argv[])
{
    printf("Start peer node test.\n");
    printf("Enter help to view the command.\n");

    while(true) {
        std::string cmdLine;
        std::getline(std::cin, cmdLine);

        if (!cmdLine.compare("e") || !cmdLine.compare("exit")) {
            printf("Stop peer node test.\n");
            break;
        }
        else if (!cmdLine.compare("h") || !cmdLine.compare("help")) {
            printf("%s", c_help);
        }
        else if (!cmdLine.compare("s") || !cmdLine.compare("start")) {
            createAndStartPeerNode();
        }
        else if (!cmdLine.compare("c") || !cmdLine.compare("conn")) {
            createConnector();
        }
        else if (!cmdLine.compare("t") || !cmdLine.compare("thread")) {
            multiConnector();
        }
    }

    return 0;
}

void createAndStartPeerNode() {
    auto cwd = getwd(nullptr);
    printf("current path: %s\n", cwd);

    std::string path(cwd);
    path.append("/PeerNode");

    gPeerNode = elastos::PeerNode::GetInstance(path);

    class Listener : public elastos::PeerListener::Listener {
        virtual std::shared_ptr<std::vector<uint8_t>> onAcquire(const ContactListener::AcquireArgs& request) {
            std::shared_ptr<std::vector<uint8_t>> response;

            switch(request.type) {
            case ElaphantContact::Listener::AcquireType::PublicKey:
                response = std::make_shared<std::vector<uint8_t>>(
                            testPublicKey.begin(), testPublicKey.end());
                break;
            case ElaphantContact::Listener::AcquireType::EncryptData:
                response = std::make_shared<std::vector<uint8_t>>(request.data);
                break;
            case ElaphantContact::Listener::AcquireType::DecryptData:
                response = std::make_shared<std::vector<uint8_t>>(request.data);
                break;
            case ElaphantContact::Listener::AcquireType::DidPropAppId:
                break;
            case ElaphantContact::Listener::AcquireType::DidAgentAuthHeader:
            {
                std::string appid = "org.elastos.microservice.test";
                std::string appkey = "b2gvzUM79yLhCbbGNWCuhSsGdqYhA7sS";
                std::string header = "id=" + appid + ";time=77777;auth=" + appkey;
                response = std::make_shared<std::vector<uint8_t>>(header.begin(), header.end());
                break;
            }
            case ElaphantContact::Listener::AcquireType::SignData:
            {
                uint8_t* signedData;
                int ret = sign(testPrivateKey.c_str(), (void*)request.data.data(), request.data.size(), (void**)&signedData);
                if (ret < 0) {
                    printf("sign failed\n");
                    return std::shared_ptr<std::vector<uint8_t>>();
                }

                response = std::make_shared<std::vector<uint8_t>>(signedData, signedData + ret);
                break;
            }

            }

            return response;
        }

        virtual void onError(int errCode, const std::string& errStr, const std::string& ext) {
            printf("PeerNode error code: %d: %s, %s\n", errCode, errStr.c_str(), ext.c_str());
        }
    };

    static std::shared_ptr<elastos::PeerListener::Listener> listener(new Listener());
    gPeerNode->SetListener(listener);

    gPeerNode->Start();
    gPeerNode->SyncInfoUploadToDidChain();
}

void createConnector()
{
    gConnector = std::make_shared<ConnectorTest>("Test");

    std::stringstream ss;
    gConnector->mConnector->GetFriendList(&ss);
    printf("Test friend list: %s\n", ss.str().c_str());
}

void threadFunc(const std::string& name)
{
    printf("Thread %s start\n", name.c_str());
    gConnectorVector.insert(gConnectorVector.begin(), std::make_shared<ConnectorTest>(name));

    std::this_thread::sleep_for(std::chrono::seconds(5));
}

void multiConnector()
{
    if (gConnectorVector.size() != 0) {
        gConnectorVector.clear();
    }

    std::thread threadArray[gServiceNameVector.size()];
    for (int i = 0; i < gServiceNameVector.size(); i++) {
        std::string name = gServiceNameVector[i];
        threadArray[i] = std::thread(threadFunc, name);
    }

    for (auto i = 0; i < gServiceNameVector.size(); i++) {
        threadArray[i].join();
    }
}