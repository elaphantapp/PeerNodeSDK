
#include <getopt.h>
#include <stdio.h>
#include <string>
#include <dlfcn.h>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <iostream>
#include "PeerNode.h"
#include "Elastos.Wallet.Utility.h"

using namespace elastos;

typedef void* (*Creator)(const char* path);

typedef void (*Destroy)(void* service);

std::condition_variable cv;
std::mutex mutex;
bool serviceRunning = false;
std::shared_ptr<elastos::PeerNode> gPeerNode;

int InitPeerNode(const std::string& path, const std::string& privateKey, const std::string& publicKey)
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
    gPeerNode->SyncInfoUploadToDidChain();
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
    std::string publicKey;

    static struct option long_options[] =
    {
        {"name", required_argument, NULL, 'n'},
        {"path", required_argument, NULL, 'p'},
        {"secret", required_argument, NULL, 's'},
        {"key", required_argument, NULL, 'k'},
        {"help", no_argument, NULL, 'h'},
        {0, 0, 0, 0}
    };

    while(1) {
        int opt_index = 0;
        c = getopt_long(argc, argv, "n:p:s:k:h", long_options, &opt_index);

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
            case 's':
                printf("param s: %s\n", argv[optind]);
                privateKey = argv[optind];
                break;
            case 'k':
                printf("param k: %s\n", argv[optind]);
                publicKey = argv[optind];
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
        printf("Please set service public key by -secret!\n");
        return -1;
    }

    if (publicKey.empty()) {
        printf("Please set service public key by -key!\n");
        return -1;
    }

    auto ret = InitPeerNode(path, privateKey, publicKey);
    if (ret != 0) {
        printf("Init peer node failed\n");
        return ret;
    }

    serviceRunning = true;
    std::thread workthread(StartService, library, path);

    while (1) {
        std::string command;
        std::getline(std::cin, command);
        if (!command.compare("exit")) {
            StopService(workthread);
            break;
        }
    }

    return EXIT_SUCCESS;
}
