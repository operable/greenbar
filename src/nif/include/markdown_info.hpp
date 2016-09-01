#ifndef GREENBAR_MARKDOWN_INFO_H
#define GREENBAR_MARKDOWN_INFO_H

#include "erl_nif.h"
#include <string>
#include "buffer.h"

namespace greenbar {

  enum MarkdownInfoType {
    MD_EOL,
    MD_TEXT,
    MD_FIXED_WIDTH,
    MD_HEADER,
    MD_ITALICS,
    MD_BOLD,
    MD_LINK
  };

  class MarkdownInfo {
  public:
    MarkdownInfoType type;
    std::string text;
    int level;
    MarkdownInfo(MarkdownInfoType info_type);
    MarkdownInfo(MarkdownInfoType info_type, const hoedown_buffer* buffer);
    MarkdownInfo(MarkdownInfoType, const hoedown_buffer* buffer, int info_level);
    ERL_NIF_TERM to_erl_term(ErlNifEnv* env);
    virtual ~MarkdownInfo();
  };
};

#endif
