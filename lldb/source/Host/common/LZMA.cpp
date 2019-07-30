//===--- Compression.cpp - Compression implementation ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/Host/Config.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"

#ifdef LLDB_ENABLE_LZMA
#include <lzma.h>
#endif // LLDB_ENABLE_LZMA

namespace lldb_private {

namespace lzma {

#ifndef LLDB_ENABLE_LZMA
bool isAvailable() { return false; }
llvm::Error getUncompressedSize(llvm::ArrayRef<uint8_t> InputBuffer,
                                uint64_t &uncompressedSize) {
  llvm_unreachable("lzma::getUncompressedSize is unavailable");
}

llvm::Error uncompress(llvm::ArrayRef<uint8_t> InputBuffer,
                       llvm::SmallVectorImpl<uint8_t> &Uncompressed) {
  llvm_unreachable("lzma::uncompress is unavailable");
}

#else // LLDB_ENABLE_LZMA

bool isAvailable() { return true; }

static const char *convertLZMACodeToString(lzma_ret Code) {
  switch (Code) {
  case LZMA_STREAM_END:
    return "lzma error: LZMA_STREAM_END";
  case LZMA_NO_CHECK:
    return "lzma error: LZMA_NO_CHECK";
  case LZMA_UNSUPPORTED_CHECK:
    return "lzma error: LZMA_UNSUPPORTED_CHECK";
  case LZMA_GET_CHECK:
    return "lzma error: LZMA_GET_CHECK";
  case LZMA_MEM_ERROR:
    return "lzma error: LZMA_MEM_ERROR";
  case LZMA_MEMLIMIT_ERROR:
    return "lzma error: LZMA_MEMLIMIT_ERROR";
  case LZMA_FORMAT_ERROR:
    return "lzma error: LZMA_FORMAT_ERROR";
  case LZMA_OPTIONS_ERROR:
    return "lzma error: LZMA_OPTIONS_ERROR";
  case LZMA_DATA_ERROR:
    return "lzma error: LZMA_DATA_ERROR";
  case LZMA_BUF_ERROR:
    return "lzma error: LZMA_BUF_ERROR";
  case LZMA_PROG_ERROR:
    return "lzma error: LZMA_PROG_ERROR";
  default:
    llvm_unreachable("unknown or unexpected lzma status code");
  }
}

llvm::Error getUncompressedSize(llvm::ArrayRef<uint8_t> InputBuffer,
                                uint64_t &uncompressedSize) {
  if (InputBuffer.size() == 0)
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "size of xz-compressed blob cannot be 0");

  auto opts = lzma_stream_flags{};
  if (InputBuffer.size() < LZMA_STREAM_HEADER_SIZE) {
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "size of xz-compressed blob (%lu bytes) is smaller than the "
        "LZMA_STREAM_HEADER_SIZE (%lu bytes)",
        InputBuffer.size(), LZMA_STREAM_HEADER_SIZE);
  }

  // Decode xz footer.
  auto xzerr = lzma_stream_footer_decode(
      &opts, InputBuffer.data() + InputBuffer.size() - LZMA_STREAM_HEADER_SIZE);
  if (xzerr != LZMA_OK) {
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "lzma_stream_footer_decode()=%s",
                                   convertLZMACodeToString(xzerr));
  }
  if (InputBuffer.size() < (opts.backward_size + LZMA_STREAM_HEADER_SIZE)) {
    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "xz-compressed buffer size (%lu bytes) too small (required at "
        "least %lu bytes) ",
        InputBuffer.size(), (opts.backward_size + LZMA_STREAM_HEADER_SIZE));
  }

  // Decode xz index.
  lzma_index *xzindex;
  uint64_t memlimit(UINT64_MAX);
  size_t inpos = 0;
  xzerr =
      lzma_index_buffer_decode(&xzindex, &memlimit, nullptr,
                               InputBuffer.data() + InputBuffer.size() -
                                   LZMA_STREAM_HEADER_SIZE - opts.backward_size,
                               &inpos, InputBuffer.size());
  if (xzerr != LZMA_OK) {
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "lzma_index_buffer_decode()=%s",
                                   convertLZMACodeToString(xzerr));
  }

  // Get size of uncompressed file to construct an in-memory buffer of the
  // same size on the calling end (if needed).
  uncompressedSize = lzma_index_uncompressed_size(xzindex);

  // Deallocate xz index as it is no longer needed.
  lzma_index_end(xzindex, nullptr);

  return llvm::Error::success();
}

llvm::Error uncompress(llvm::ArrayRef<uint8_t> InputBuffer,
                       llvm::SmallVectorImpl<uint8_t> &Uncompressed) {
  if (InputBuffer.size() == 0)
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "size of xz-compressed blob cannot be 0");

  uint64_t uncompressedSize = 0;
  auto err = getUncompressedSize(InputBuffer, uncompressedSize);
  if (err)
    return err;

  Uncompressed.resize(uncompressedSize);

  // Decompress xz buffer to buffer.
  uint64_t memlimit(UINT64_MAX);
  size_t inpos = 0;
  inpos = 0;
  size_t outpos = 0;
  auto xzerr = lzma_stream_buffer_decode(
      &memlimit, 0, nullptr, InputBuffer.data(), &inpos, InputBuffer.size(),
      Uncompressed.data(), &outpos, Uncompressed.size());
  if (xzerr != LZMA_OK) {
    return llvm::createStringError(llvm::inconvertibleErrorCode(),
                                   "lzma_stream_buffer_decode()=%s",
                                   convertLZMACodeToString(xzerr));
  }

  return llvm::Error::success();
}

#endif // LLDB_ENABLE_LZMA

} // end of namespace lzma
} // namespace lldb_private
