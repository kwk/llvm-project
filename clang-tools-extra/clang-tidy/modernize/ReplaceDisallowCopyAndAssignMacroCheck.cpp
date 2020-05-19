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
      const std::string &MacroName, const bool FinalizeWithSemicolon)
      : Check(Check), PP(PP), SM(SM), MacroName(MacroName),
        FinalizeWithSemicolon(FinalizeWithSemicolon) {}

  void MacroExpands(const Token &MacroNameTok, const MacroDefinition &MD,
                    SourceRange Range, const MacroArgs *Args) override {
    auto identifierInfo = MacroNameTok.getIdentifierInfo();
    if (!identifierInfo)
      return;
    if (Args->getNumMacroArguments() != 1)
      return;
    auto name = identifierInfo->getNameStart();
    if (std::strncmp(MacroName.c_str(), name, MacroName.length()) != 0)
      return;
    // The first argument to the DISALLOW_COPY_AND_ASSIGN macro is exptected to
    // be the class name.
    auto classNameTok = Args->getUnexpArgument(0);
    auto c = std::string(classNameTok->getIdentifierInfo()->getNameStart());
    auto expansionRange = PP.getSourceManager().getExpansionRange(Range);
    std::string Replacement = c + "(const " + c + " &) = delete;";
    Replacement += "const " + c + " &operator=(const " + c + " &) = delete";
    if (FinalizeWithSemicolon)
      Replacement += ";";
    Check.diag(MacroNameTok.getLocation(), "using copy and assign macro '%0'")
        << MacroName
        << FixItHint::CreateReplacement(expansionRange, Replacement);
  }

  ClangTidyCheck &Check;
  Preprocessor &PP;
  const SourceManager &SM;

  const std::string MacroName;
  const bool FinalizeWithSemicolon;
};
} // namespace

ReplaceDisallowCopyAndAssignMacroCheck::ReplaceDisallowCopyAndAssignMacroCheck(
    StringRef Name, ClangTidyContext *Context)
    : ClangTidyCheck(Name, Context),
      MacroName(Options.get("MacroName", "DISALLOW_COPY_AND_ASSIGN")),
      FinalizeWithSemicolon(Options.get("FinalizeWithSemicolon", false)) {}

void ReplaceDisallowCopyAndAssignMacroCheck::registerPPCallbacks(
    const SourceManager &SM, Preprocessor *PP, Preprocessor *ModuleExpanderPP) {
  PP->addPPCallbacks(
      ::std::make_unique<ReplaceDisallowCopyAndAssignMacroCallbacks>(
          *this, *ModuleExpanderPP, SM, MacroName, FinalizeWithSemicolon));
}

void ReplaceDisallowCopyAndAssignMacroCheck::storeOptions(
    ClangTidyOptions::OptionMap &Opts) {
  Options.store(Opts, "MacroName", MacroName);
  Options.store(Opts, "FinalizeWithSemicolon", FinalizeWithSemicolon);
}

} // namespace modernize
} // namespace tidy
} // namespace clang
