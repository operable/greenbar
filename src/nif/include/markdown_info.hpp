#ifndef GREENBAR_MARKDOWN_INFO_H
#define GREENBAR_MARKDOWN_INFO_H

#include "erl_nif.h"
#include <string>
#include "buffer.h"

namespace greenbar {
  class MarkdownInfo {
  public:
    std::string name;
    std::string text;
    int level;
    MarkdownInfo(std::string info_name, std::string info_text);
    MarkdownInfo(std::string info_name, const hoedown_buffer* buffer);
    MarkdownInfo(std::string info_name, const hoedown_buffer* buffer, int info_level);
    ERL_NIF_TERM to_erl_term(ErlNifEnv* env);
    virtual ~MarkdownInfo();
  };
};

#endif
