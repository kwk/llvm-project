//===--- ReplaceDisallowCopyAndAssignMacroCheck.cpp - clang-tidy ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ReplaceDisallowCopyAndAssignMacroCheck.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Lex/MacroArgs.h"

using namespace clang::ast_matchers;

namespace clang {
namespace tidy {
namespace modernize {

namespace {
class ReplaceDisallowCopyAndAssignMacroCallbacks : public PPCallbacks {
public:
  explicit ReplaceDisallowCopyAndAssignMacroCallbacks(
      ClangTidyCheck &Check, Preprocessor &PP, const SourceManager &SM,
      const std::string &MacroName)
      : Check(Check), PP(PP), SM(SM), MacroName(MacroName)
  {}

  /// Hook called whenever a macro definition is seen.
  void MacroDefined(const Token &MacroNameTok,
                    const MacroDirective *MD) override {
    auto identifierInfo = MacroNameTok.getIdentifierInfo();
    if (!identifierInfo)
      return;

    auto name = identifierInfo->getNameStart();

    if (std::strncmp(MacroName.c_str(), name, MacroName.length()) != 0)
      return;

    auto removeRange = MacroNameTok.getLocation();
    Check.diag(MacroNameTok.getLocation(), "remove '%0' macro")
        << MacroName << FixItHint::CreateRemoval(removeRange);
  }

  /// Called by Preprocessor::HandleMacroExpandedIdentifier when a
  /// macro invocation is found.
  void MacroExpands(const Token &MacroNameTok, const MacroDefinition &MD,
                    SourceRange Range, const MacroArgs *Args) override {
    auto identifierInfo = MacroNameTok.getIdentifierInfo();
    if (!identifierInfo)
      return;
    auto name = identifierInfo->getNameStart();
    if (std::strncmp(MacroName.c_str(), name, MacroName.length()) != 0)
      return;
    if (Args->getNumMacroArguments() != 1)
      return;
    // The first argument to the DISALLOW_COPY_AND_ASSIGN macro is usually a
    // class name.
    auto classNameTok = Args->getUnexpArgument(0);
    auto cls = std::string(classNameTok->getIdentifierInfo()->getNameStart());
    auto expansionRange = PP.getSourceManager().getExpansionRange(Range);
    // fprintf(stderr, "expansion range begin: %s %s\n",
    // expansionRange.getBegin().printToString(PP.getSourceManager()).c_str(),
    // cls.c_str());
    std::string Replacement =
        (llvm::Twine("") + "" + cls + "(const " + cls + " &) = delete;const " +
         cls + " &operator=(const " + cls + " &) = delete;")
            .str();
    Check.diag(MacroNameTok.getLocation(), "using copy and assign macro '%0'")
        << MacroName
        << FixItHint::CreateReplacement(expansionRange, Replacement);
  }

  ClangTidyCheck &Check;
  Preprocessor &PP;
  const SourceManager &SM;
  const std::string MacroName;
};
} // namespace

ReplaceDisallowCopyAndAssignMacroCheck::ReplaceDisallowCopyAndAssignMacroCheck(
    StringRef Name, ClangTidyContext *Context)
    : ClangTidyCheck(Name, Context),
      MacroName(Options.get("MacroName", "DISALLOW_COPY_AND_ASSIGN")) {}

void ReplaceDisallowCopyAndAssignMacroCheck::registerPPCallbacks(
    const SourceManager &SM, Preprocessor *PP, Preprocessor *ModuleExpanderPP) {
  PP->addPPCallbacks(
      ::std::make_unique<ReplaceDisallowCopyAndAssignMacroCallbacks>(
          *this, *ModuleExpanderPP, SM, MacroName));
}

void ReplaceDisallowCopyAndAssignMacroCheck::storeOptions(
    ClangTidyOptions::OptionMap &Opts) {
  Options.store(Opts, "MacroName", MacroName);
}

} // namespace modernize
} // namespace tidy
} // namespace clang
