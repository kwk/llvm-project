//===-- DebugInfoD.cpp ----------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/Core/Module.h"
#include "lldb/Host/Config.h"
#include "lldb/Symbol/ObjectFile.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include "lldb/Host/DebugInfoD.h"

#if LLDB_ENABLE_DEBUGINFOD
#include "elfutils/debuginfod.h"
#endif

namespace lldb_private {

namespace debuginfod {

using namespace lldb;
using namespace lldb_private;

#if !LLDB_ENABLE_DEBUGINFOD
bool isAvailable() { return false; }

UUID getBuildIDFromModule(const ModuleSP &module) {
  llvm_unreachable("debuginfod::getBuildIDFromModule is unavailable");
};

llvm::Error findSource(UUID buildID, const std::string &path,
                       std::string &cache_path, sys::TimePoint<> &mod_time) {
  llvm_unreachable("debuginfod::findSource is unavailable");
}

#else // LLDB_ENABLE_DEBUGINFOD

bool isAvailable() { return true; }

UUID getBuildIDFromModule(const ModuleSP &module) {
  UUID buildID;

  if (!module)
    return buildID;

  const FileSpec &moduleFileSpec = module->GetFileSpec();
  ModuleSpecList specList;
  size_t nSpecs =
      ObjectFile::GetModuleSpecifications(moduleFileSpec, 0, 0, specList);

  for (size_t i = 0; i < nSpecs; i++) {
    ModuleSpec spec;
    if (!specList.GetModuleSpecAtIndex(i, spec))
      continue;

    const UUID &uuid = spec.GetUUID();
    if (!uuid.IsValid())
      continue;

    buildID = uuid;
    break;
  }
  return buildID;
}

llvm::Error findSource(UUID buildID, const std::string &path,
                       std::string &result_path) {
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

  if (rc < 0)
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "debuginfod_find_source query failed: %s",
                                   strerror(-rc));

  if (cache_path) {
    result_path = std::string(cache_path);
    free(cache_path);
  }

  llvm::Error err = llvm::Error::success();
  if (close(rc) < 0) {
    err = llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "failed to close result of call to debuginfo_find_source: %s",
        strerror(errno));
  }

  debuginfod_end(client);

  return err;
}

#endif // LLDB_ENABLE_DEBUGINFOD

} // end of namespace debuginfod
} // namespace lldb_private
