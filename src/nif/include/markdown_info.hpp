#ifndef GREENBAR_MARKDOWN_INFO_H
#define GREENBAR_MARKDOWN_INFO_H

#include "erl_nif.h"
#include <memory>
#include <string>
#include <cstring>
#include <vector>
#include "buffer.h"
#include "gb_common.hpp"

namespace greenbar {

  enum MarkdownInfoType {
    MD_EOL,
    MD_TEXT,
    MD_FIXED_WIDTH,
    MD_HEADER,
    MD_ITALICS,
    MD_BOLD,
    MD_LINK,
    MD_LIST_ITEM,
    MD_ORDERED_LIST,
    MD_UNORDERED_LIST,
    MD_NONE
  };

  class MarkdownInfo {
  public:
    virtual ~MarkdownInfo() { };
    virtual MarkdownInfoType get_type() = 0;
    virtual bool is_leaf() { return false; };
    virtual ERL_NIF_TERM to_erl_term(ErlNifEnv* env) = 0;
  };

  class MarkdownLeafInfo : public MarkdownInfo {
  private:
    MarkdownInfoType type_;
    std::string text_;
    std::string url_;
    int level_;

    // No copying
    MarkdownLeafInfo(MarkdownLeafInfo const &);
    MarkdownLeafInfo &operator=(MarkdownLeafInfo const &);
  public:
    MarkdownLeafInfo(MarkdownInfoType type);
    virtual ~MarkdownLeafInfo() { };
    ERL_NIF_TERM to_erl_term(ErlNifEnv* env);
    MarkdownInfoType get_type();
    void set_type(MarkdownInfoType type);
    void set_text(std::string text);
    void set_url(std::string url);
    void set_level(int level);
  };

  class MarkdownParentInfo : public MarkdownInfo {
  private:
    std::vector<MarkdownInfo*> children_;
    MarkdownInfoType type_;

    // No copying
    MarkdownParentInfo(MarkdownParentInfo const &);
    MarkdownParentInfo &operator=(MarkdownParentInfo const &);
    ERL_NIF_TERM convert_children(ErlNifEnv* env);
  public:
    MarkdownParentInfo(MarkdownInfoType type);
    virtual ~MarkdownParentInfo();
    void add_child(MarkdownInfo* child);
    ERL_NIF_TERM to_erl_term(ErlNifEnv* env);
    MarkdownInfoType get_type();
  };

  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type);
  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* buffer);
  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* buffer, int info_level);
  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* text, const hoedown_buffer* url);

  MarkdownLeafInfo* as_leaf(MarkdownInfo* info);

  ERL_NIF_TERM type_to_atom(greenbar::MarkdownInfoType type, gb_priv_s* priv_data);
}

#endif
