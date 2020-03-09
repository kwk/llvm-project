//===-- DebugInfoD.cpp ----------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/Host/DebugInfoD.h"
#include "lldb/Core/Module.h"
#include "lldb/Host/Config.h"
#include "lldb/Symbol/ObjectFile.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Errno.h"

#if LLDB_ENABLE_DEBUGINFOD
#include "elfutils/debuginfod.h"
#endif

namespace lldb_private {

namespace debuginfod {

using namespace lldb;
using namespace lldb_private;

#if !LLDB_ENABLE_DEBUGINFOD
bool isAvailable() { return false; }

llvm::Error findSource(UUID buildID, const std::string &path,
                       std::string &cache_path) {
  llvm_unreachable("debuginfod::findSource is unavailable");
}

#else // LLDB_ENABLE_DEBUGINFOD

bool isAvailable() { return true; }

llvm::Expected<std::string> findSource(UUID buildID, const std::string &path) {
  if (!buildID.IsValid())
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "invalid build ID: %s",
                                   buildID.GetAsString("").c_str());

  debuginfod_client *client = debuginfod_begin();

  if (!client)
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "failed to create debuginfod connection handle: %s", strerror(errno));

  // debuginfod_set_progressfn(client, [](debuginfod_client *client, long a,
  //                                 long b) -> int {
  //   fprintf(stderr, "KWK === a: %ld b : %ld \n", a, b);
  //   return 0; // continue
  // });

  char *cache_path = nullptr;
  int rc = debuginfod_find_source(client, buildID.GetBytes().data(),
                                  buildID.GetBytes().size(), path.c_str(),
                                  &cache_path);

  debuginfod_end(client);

  std::string result_path;
  if (cache_path) {
    result_path = std::string(cache_path);
    free(cache_path);
  }

  if (rc < 0) {
    if (rc == -ENOSYS) // No DEBUGINFO_URLS were specified
      return result_path;
    else if (rc == -ENOENT) // No such file or directory, aka build-id not
                            // available on servers.
      return result_path;
    else
      return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                     "debuginfod_find_source query failed: %s",
                                     llvm::sys::StrError(-rc).c_str());
  }

  if (close(rc) < 0) {
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "failed to close result of call to debuginfo_find_source: %s",
        llvm::sys::StrError(errno).c_str());
  }

  return result_path;
}

#endif // LLDB_ENABLE_DEBUGINFOD

} // end of namespace debuginfod
} // namespace lldb_private
