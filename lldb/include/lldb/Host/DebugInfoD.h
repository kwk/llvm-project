//===-- DebugInfoD.h --------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_HOST_DEBUGINFOD_H
#define LLDB_HOST_DEBUGINFOD_H

#include "lldb/Utility/UUID.h"

namespace llvm {
class Error;
} // End of namespace llvm

namespace lldb_private {

namespace debuginfod {
	
bool isAvailable();

UUID getBuildIDFromModule(const lldb::ModuleSP &module);

llvm::Error findSource(UUID buildID, const std::string &path,
                       std::string &result_path);

} // End of namespace debuginfod

} // End of namespace lldb_private

#endif // LLDB_HOST_DEBUGINFOD_H
