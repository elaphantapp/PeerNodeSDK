#ifndef _CROSSPL_CROSSBASE_HPP_
#define _CROSSPL_CROSSBASE_HPP_

#include <cstdint>
#include <memory>
//#include <CrossPLFactory.hpp>

extern "C" {
void RegCreateCppObjFunc(int64_t(*func)(const char*));
void RegDestroyCppObjFunc(int(*func)(const char*,int64_t));

void RegCreateswiftObjFunc(int64_t(*func)(const char*,int64_t));
void RegDestroyswiftObjFunc(int(*func)(const char*,int64_t));
} // extern "C"

namespace crosspl {
namespace native {
  
class CrossBase {
public:
  /*** type define ***/
//  explicit CrossBase(int64_t platformHandle);
  explicit CrossBase();
  virtual ~CrossBase();

  /*** static function and variable ***/
  static int64_t CreateNativeObject(const char* swiftClassName);
  static void DestroyNativeObject(const char* swiftClassName, int64_t nativeHandle);

  static int64_t CreatePlatformObject(const char* cppClassName, int64_t nativeHandle);
  static void DestroyPlatformObject(const char* cppClassName, int64_t platformHandle);

  /*** class function and variable ***/
  void bindPlatformHandle(int64_t platformHandle);
  void unbindPlatformHandle(int64_t platformHandle);

  int64_t getPlatformHandle() const;

private:
  /*** type define ***/

  /*** static function and variable ***/

  /*** class function and variable ***/
  int64_t mPlatformHandle;

}; // class CrossBase

} //namespace native
} //namespace crosspl

#endif /* _CROSSPL_CROSSBASE_HPP_ */
