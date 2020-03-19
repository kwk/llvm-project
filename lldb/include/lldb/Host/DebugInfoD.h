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
#include "llvm/ADT/Optional.h"
#include "llvm/Support/Error.h"

namespace lldb_private {

namespace debuginfod {

// Returns \c true if debuginfod support was compiled-in; otherwise \c false is
// returned.
bool isAvailable();

// Asks all servers in environment variable \c DEBUGINFOD_URLS for the \a path
// of an artifact with a given \a buildID and returns the path to a locally
// cached version of the file. If there  was an error, we return that instead.
llvm::Expected<std::string> findSource(UUID buildID, const std::string &path);

} // End of namespace debuginfod

} // End of namespace lldb_private

#endif // LLDB_HOST_DEBUGINFOD_H
