
#include <getopt.h>
#include <stdio.h>
#include <string>
#include <dlfcn.h>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <iostream>
#include <fstream>
#include "PeerNode.h"
#include "Elastos.Wallet.Utility.h"

using namespace elastos;

typedef void* (*Creator)(const char* path);

typedef void (*Destroy)(void* service);

std::condition_variable cv;
std::mutex mutex;
bool serviceRunning = false;
std::shared_ptr<elastos::PeerNode> gPeerNode;

int WriteToFile(const std::string& path, const char* data, std::size_t size) {
    std::string tmp_path(path);
    tmp_path.append(".tmp");

    std::ofstream ofs(tmp_path, std::ios::binary);
    if (ofs.is_open() == false) {
        fprintf(stderr, "Failed to write to file: can't open %s.", path.c_str());
        return -1;
    }

    ofs.write(data, size);

    ofs.flush();
    ofs.close();

    // rename tmp ==> path
    int ret = std::rename(tmp_path.c_str(), path.c_str());
    if (ret < 0) {
        fprintf(stderr, "Failed to write to file: %s, err=%d", path.c_str(), ret);
        return ret;
    }

    return 0;
}

int InitPeerNode(const std::string& path, const std::string& privateKey, const char* publicKey,
                 const std::string& infoPath)
{
    gPeerNode = elastos::PeerNode::GetInstance(path);
    if (gPeerNode.get() == nullptr) {
        printf("Create peer node failed!\n");
        return -1;
    }

    class Listener : public elastos::PeerListener::Listener {
    public:
        Listener(const std::string& privateKey, const std::string& publicKey)
            : mPrivateKey(privateKey)
            , mPublicKey(publicKey)
        {}

        virtual std::shared_ptr<std::vector<uint8_t>> onAcquire(const ElaphantContact::Listener::AcquireArgs& request) {
            std::shared_ptr<std::vector<uint8_t>> response;

            switch(request.type) {
            case ElaphantContact::Listener::AcquireType::PublicKey:
                response = std::make_shared<std::vector<uint8_t>>(mPublicKey.begin(), mPublicKey.end());
                break;
            case ElaphantContact::Listener::AcquireType::EncryptData:
                response = std::make_shared<std::vector<uint8_t>>(request.data);
                break;
            case ElaphantContact::Listener::AcquireType::DecryptData:
                response = std::make_shared<std::vector<uint8_t>>(request.data);
                break;
            case ElaphantContact::Listener::AcquireType::DidPropAppId:
            {
                std::string appId = "DC92DEC59082610D1D4698F42965381EBBC4EF7DBDA08E4B3894D530608A64AA"
                                    "A65BB82A170FBE16F04B2AF7B25D88350F86F58A7C1F55CC29993B4C4C29E405";
                response = std::make_shared<std::vector<uint8_t>>(appId.begin(), appId.end());
                break;
            }
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
                int ret = sign(mPrivateKey.c_str(), (void*)request.data.data(), request.data.size(), (void**)&signedData);
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

    private:
        std::string mPrivateKey;
        std::string mPublicKey;
    };

    static std::shared_ptr<elastos::PeerListener::Listener> listener(new Listener(privateKey, publicKey));
    gPeerNode->SetListener(listener);

    auto ret = gPeerNode->Start();
    if(ret < 0) {
        fprintf(stderr, "Error: Failed to start PeerNode\n");
        return ret;
    }

    ret = gPeerNode->SyncInfoUploadToDidChain();
    if(ret < 0) {
        fprintf(stderr, "Error: Failed to sync info upload to DidChain\n");
        return ret;
    }

    if(infoPath.empty() == false) {
        printf("Save user info to %s\n", infoPath.c_str());

        auto userInfo = gPeerNode->GetUserInfo();
        std::string did;
        std::string carrierAddr;
        ret = userInfo->getHumanInfo(ElaphantContact::UserInfo::Item::Did, did);
        if(ret < 0) {
            fprintf(stderr, "Error: Failed to get user did\n");
        }
        ret = userInfo->getCurrDevCarrierAddr(carrierAddr);
        if(ret < 0) {
            fprintf(stderr, "Error: Failed to get current device CarrierAddr\n");
        }

        std::stringstream sstream;
        sstream << "{";
        sstream << "\"PrivateKey\":\"" << privateKey << "\"";
        sstream << ",";
        sstream << "\"Did\":\"" << did << "\"";
        sstream << ",";
        sstream << "\"CarrierAddr\":\"" << carrierAddr << "\"";
        sstream << "}";

        std::string info = sstream.str();
        ret = WriteToFile(infoPath, info.data(), info.length());
        if(ret < 0) {
            fprintf(stderr, "Error: Failed to save info to %s\n", infoPath.c_str());
        }
    }

    return ret;
}

void StartService(const std::string& library, const std::string& path)
{
    void *handle = dlopen(library.c_str(), RTLD_LAZY);
    if (!handle) {
        /* fail to load the library */
        fprintf(stderr, "Error: %s\n", dlerror());
        return;
    }

    Creator CreateService;
    void* service;
    int ret;

    *(void**)(&CreateService) = dlsym(handle, "CreateService");
    if (CreateService == NULL) {
        fprintf(stderr, "Error: %s\n", dlerror());
        dlclose(handle);
        return;
    }

    service = CreateService(path.c_str());
    if (service == NULL) {
        fprintf(stderr, "Create Service failed!\n");
        dlclose(handle);
        return;
    }

    std::unique_lock<std::mutex> lk(mutex);
    while (serviceRunning) {
        cv.wait(lk);
    }

    Destroy DestroyService;
    *(void**)(&DestroyService) = dlsym(handle, "DestroyService");
    if (CreateService == NULL) {
        fprintf(stderr, "Error: %s\n", dlerror());
        dlclose(handle);
        return;
    }

    DestroyService(service);
    dlclose(handle);
}

void StopService(std::thread& workthread) {
    std::unique_lock<std::mutex> lk(mutex);
    serviceRunning = false;
    lk.unlock();
    cv.notify_one();

    workthread.join();
}

int main(int argc, char* argv[])
{
    int c;
    std::string library;
    std::string path;
    std::string privateKey;
    std::string infoPath;
    char* publicKey = nullptr;

    static struct option long_options[] =
    {
        {"name", required_argument, NULL, 'n'},
        {"path", required_argument, NULL, 'p'},
        {"key", required_argument, NULL, 'k'},
        {"infopath", required_argument, NULL, 'i'},
        {"help", no_argument, NULL, 'h'},
        {0, 0, 0, 0}
    };

    while(1) {
        int opt_index = 0;
        c = getopt_long(argc, argv, "n:p:k:i:h", long_options, &opt_index);

        if (-1 == c) {
            break;
        }

        switch(c) {
            case 'n':
                printf("param n: %s\n", argv[optind]);
                library = argv[optind];
                break;
            case 'p':
                printf("param p: %s\n", argv[optind]);
                path = argv[optind];
                break;
            case 'k':
                printf("param k: %s\n", argv[optind]);
                privateKey = argv[optind];
                break;
            case 'i':
                printf("param i: %s\n", argv[optind]);
                infoPath = argv[optind];
                break;
            default:
                printf("param default: %s\n", argv[optind]);
                break;
        }
    }

    if (library.empty()) {
        printf("Please set service library by -name!\n");
        return -1;
    }

    if (path.empty()) {
        printf("Please set service local path by -path!\n");
        return -1;
    }

    if (privateKey.empty()) {
        printf("Please set service private key by -key!\n");
        return -1;
    }

    publicKey = getPublicKeyFromPrivateKey(privateKey.c_str());
    if (!publicKey) {
        printf("Get public key from private key failed!\n");
        return -1;
    }

    char* did = getDid(publicKey);
    auto ret = InitPeerNode(path, privateKey, publicKey, infoPath);
    if (ret != 0) {
        printf("Init peer node failed\n");
        free(publicKey);
        return ret;
    }

    serviceRunning = true;
    std::stringstream ss;
    ss << path << "/" << did;
    std::thread workthread(StartService, library, ss.str());

    while (1) {
        std::string command;
        std::getline(std::cin, command);
        if (!command.compare("exit")) {
            StopService(workthread);
            break;
        }
    }

    free(publicKey);
    free(did);
    return EXIT_SUCCESS;
}
