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
/// Information about an opening preprocessor directive.
struct PreprocessorEntry {
  SourceLocation Loc;
  /// Condition used after the preprocessor directive.
  std::string Condition;
};

class ReplaceDisallowCopyAndAssignMacroCallbacks : public PPCallbacks {
//   enum DirectiveKind { DK_If = 0, DK_Ifdef = 1, DK_Ifndef = 2 };

public:
  explicit ReplaceDisallowCopyAndAssignMacroCallbacks(ClangTidyCheck &Check,
                                          Preprocessor &PP, const SourceManager &SM, const std::string &MacroName)
      : Check(Check), PP(PP), SM(SM), MacroName(MacroName)
        // WarningDescription("nested redundant %select{#if|#ifdef|#ifndef}0; "
        //                    "consider removing it"),
        // NoteDescription("previous %select{#if|#ifdef|#ifndef}0 was here")
  {}
  /// Hook called whenever a macro definition is seen.
  void MacroDefined(const Token &MacroNameTok,
                    const MacroDirective *MD) override {
    // auto macroInfo = MD->getMacroInfo();
    // auto isFunctionLike = macroInfo->isFunctionLike();
    // if (isFunctionLike) {
    //   fprintf(stderr, "found macro definition: %s is function like: %d %s\n",
    //           MacroNameTok.getName(), isFunctionLike, MacroNameTok.getIdentifierInfo()->getNameStart());
    //   MD->dump();
    //   macroInfo->dump();
      
    // }
  }

  /// Called by Preprocessor::HandleMacroExpandedIdentifier when a
  /// macro invocation is found.
  void MacroExpands(const Token &MacroNameTok,
                            const MacroDefinition &MD, SourceRange Range,
                            const MacroArgs *Args) override {
    auto identifierInfo = MacroNameTok.getIdentifierInfo();
    if (!identifierInfo)
      return;
    
    auto name = identifierInfo->getNameStart();
    
    if (std::strncmp(MacroName.c_str(), name, MacroName.length()) != 0)
      return;
    
    fprintf(stderr, "macro args: %d\n", Args->getNumMacroArguments());
    if (Args->getNumMacroArguments() != 1)
      return;
  
    // fprintf(stderr, "line: %d\n", PP.getSourceManager().getExpansionLineNumber());
    // fprintf(stderr, "col: %d\n", PP.getSourceManager().getExpansionColumnNumber());
    auto expansionRange = PP.getSourceManager().getExpansionRange(Range);
    fprintf(stderr, "expansion range begin: %s\n", expansionRange.getBegin().printToString(PP.getSourceManager()).c_str());

    
    Range.dump(PP.getSourceManager());
  }

//   void If(SourceLocation Loc, SourceRange ConditionRange,
//           ConditionValueKind ConditionValue) override {
//     StringRef Condition =
//         Lexer::getSourceText(CharSourceRange::getTokenRange(ConditionRange),
//                              PP.getSourceManager(), PP.getLangOpts());
//     CheckMacroRedundancy(Loc, Condition, IfStack, DK_If, DK_If, true);
//   }

//   void Ifdef(SourceLocation Loc, const Token &MacroNameTok,
//              const MacroDefinition &MacroDefinition) override {
//     std::string MacroName = PP.getSpelling(MacroNameTok);
//     CheckMacroRedundancy(Loc, MacroName, IfdefStack, DK_Ifdef, DK_Ifdef, true);
//     CheckMacroRedundancy(Loc, MacroName, IfndefStack, DK_Ifdef, DK_Ifndef,
//                          false);
//   }

//   void Ifndef(SourceLocation Loc, const Token &MacroNameTok,
//               const MacroDefinition &MacroDefinition) override {
//     std::string MacroName = PP.getSpelling(MacroNameTok);
//     CheckMacroRedundancy(Loc, MacroName, IfndefStack, DK_Ifndef, DK_Ifndef,
//                          true);
//     CheckMacroRedundancy(Loc, MacroName, IfdefStack, DK_Ifndef, DK_Ifdef,
//                          false);
//   }

//   void Endif(SourceLocation Loc, SourceLocation IfLoc) override {
//     if (!IfStack.empty() && IfLoc == IfStack.back().Loc)
//       IfStack.pop_back();
//     if (!IfdefStack.empty() && IfLoc == IfdefStack.back().Loc)
//       IfdefStack.pop_back();
//     if (!IfndefStack.empty() && IfLoc == IfndefStack.back().Loc)
//       IfndefStack.pop_back();
//   }

// private:
//   void CheckMacroRedundancy(SourceLocation Loc, StringRef MacroName,
//                             SmallVector<PreprocessorEntry, 4> &Stack,
//                             DirectiveKind WarningKind, DirectiveKind NoteKind,
//                             bool Store) {
//     if (PP.getSourceManager().isInMainFile(Loc)) {
//       for (const auto &Entry : Stack) {
//         if (Entry.Condition == MacroName) {
//           Check.diag(Loc, WarningDescription) << WarningKind;
//           Check.diag(Entry.Loc, NoteDescription, DiagnosticIDs::Note)
//               << NoteKind;
//         }
//       }
//     }

//     if (Store)
//       // This is an actual directive to be remembered.
//       Stack.push_back({Loc, std::string(MacroName)});
//   }

  ClangTidyCheck &Check;
  Preprocessor &PP;
  const SourceManager &SM;
  const std::string MacroName;
//   SmallVector<PreprocessorEntry, 4> IfStack;
//   SmallVector<PreprocessorEntry, 4> IfdefStack;
//   SmallVector<PreprocessorEntry, 4> IfndefStack;
//   const std::string WarningDescription;
//   const std::string NoteDescription;
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
