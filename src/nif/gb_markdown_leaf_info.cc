#include "erl_nif.h"
#include "markdown_info.hpp"
#include "gb_common.hpp"

namespace greenbar {

  MarkdownLeafInfo::MarkdownLeafInfo(MarkdownInfoType info_type) {
    type_ = info_type;
    text_ = "";
    url_ = "";
    level_ = -1;
  }

  MarkdownInfoType MarkdownLeafInfo::get_type() {
    return type_;
  }

  void MarkdownLeafInfo::set_type(MarkdownInfoType type) {
    type_ = type;
  }

  void MarkdownLeafInfo::set_text(std::string text) {
    text_ = text;
  }

  void MarkdownLeafInfo::set_url(std::string url) {
    url_ = url;
  }

  void MarkdownLeafInfo::set_level(int level) {
    level_ = level;
  }

  ERL_NIF_TERM MarkdownLeafInfo::to_erl_term(ErlNifEnv* env) {
    gb_priv_s *priv_data = (gb_priv_s*) enif_priv_data(env);
    ERL_NIF_TERM type_name = type_to_atom(this->type_, priv_data);
    ERL_NIF_TERM retval = enif_make_new_map(env);
    enif_make_map_put(env, retval, priv_data->gb_atom_name, type_name, &retval);
    if (this->get_type() != MD_EOL) {
      ERL_NIF_TERM text;
      auto contents = enif_make_new_binary(env, this->text_.size(), &text);
      memcpy(contents, this->text_.c_str(), this->text_.size());
      enif_make_map_put(env, retval, priv_data->gb_atom_text, text, &retval);

      if (this->type_ == MD_HEADER) {
        ERL_NIF_TERM level = enif_make_int(env, this->level_);
        enif_make_map_put(env, retval, priv_data->gb_atom_level, level, &retval);
      }

      if (this->type_ == MD_LINK) {
        ERL_NIF_TERM url;
        auto contents = enif_make_new_binary(env, this->url_.size(), &url);
        memcpy(contents, this->url_.c_str(), this->url_.size());
        enif_make_map_put(env, retval, priv_data->gb_atom_url, url, &retval);
      }
    }
    return retval;
  }

  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* buf) {
    auto retval = new MarkdownLeafInfo(info_type);
    retval->set_text(std::string((char*) buf->data, buf->size));
    return retval;
  }

  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* buf, int info_level) {
    auto retval = new MarkdownLeafInfo(info_type);
    retval->set_text(std::string((char*) buf->data, buf->size));
    retval->set_level(info_level);
    return retval;
  }

  MarkdownLeafInfo* new_leaf(MarkdownInfoType info_type, const hoedown_buffer* title, const hoedown_buffer* link) {
    auto retval = new MarkdownLeafInfo(info_type);
    retval->set_text(std::string((char*) title->data, title->size));
    retval->set_url(std::string((char*) link->data, link->size));
    return retval;
  }

  MarkdownLeafInfo* as_leaf(MarkdownInfo* info) {
    if (info) {
      return dynamic_cast<MarkdownLeafInfo*>(info);
    }
    return nullptr;
  }

  ERL_NIF_TERM type_to_atom(greenbar::MarkdownInfoType type, gb_priv_s* priv_data) {
    switch(type) {
    case greenbar::MD_EOL:
      return priv_data->gb_atom_newline;
    case greenbar::MD_FIXED_WIDTH:
      return priv_data->gb_atom_fixed_width;
    case greenbar::MD_HEADER:
      return priv_data->gb_atom_header;
    case greenbar::MD_ITALICS:
      return priv_data->gb_atom_italics;
    case greenbar::MD_BOLD:
      return priv_data->gb_atom_bold;
    case greenbar::MD_LINK:
      return priv_data->gb_atom_link;
    case greenbar::MD_ORDERED_LIST:
      return priv_data->gb_atom_ordered_list;
    case greenbar::MD_UNORDERED_LIST:
      return priv_data->gb_atom_unordered_list;
    case greenbar::MD_LIST_ITEM:
      return priv_data->gb_atom_list_item;
    default:
      return priv_data->gb_atom_text;
    }
  }

}
