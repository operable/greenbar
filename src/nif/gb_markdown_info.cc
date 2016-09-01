#include "erl_nif.h"
#include "markdown_info.hpp"
#include "gb_common.hpp"

static ERL_NIF_TERM type_to_atom(greenbar::MarkdownInfoType type, gb_priv_s* priv_data) {
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
  default:
    return priv_data->gb_atom_text;
  }
}

namespace greenbar {

  MarkdownInfo::MarkdownInfo(MarkdownInfoType info_type, const hoedown_buffer* buf) {
    type = info_type;
    text = std::string((char*) buf->data, buf->size);
    level = -1;
  }

  MarkdownInfo::MarkdownInfo(MarkdownInfoType info_type, const hoedown_buffer* buf, int info_level) {
    type = info_type;
    text = std::string((char*) buf->data, buf->size);
    level = info_level;
  }

  MarkdownInfo::MarkdownInfo(MarkdownInfoType info_type) {
    type = info_type;
    text = "";
    level = -1;
  }

  ERL_NIF_TERM MarkdownInfo::to_erl_term(ErlNifEnv* env) {
    gb_priv_s *priv_data = (gb_priv_s*) enif_priv_data(env);
    ERL_NIF_TERM type_name = type_to_atom(this->type, priv_data);
    ERL_NIF_TERM retval = enif_make_new_map(env);
    enif_make_map_put(env, retval, priv_data->gb_atom_name, type_name, &retval);
    if (this->type != MD_EOL) {
      ERL_NIF_TERM text;
      auto contents = enif_make_new_binary(env, this->text.size(), &text);
      memcpy(contents, this->text.c_str(), this->text.size());
      enif_make_map_put(env, retval, priv_data->gb_atom_text, text, &retval);
      if (this->type == MD_HEADER) {
        ERL_NIF_TERM level = enif_make_int(env, this->level);
        enif_make_map_put(env, retval, priv_data->gb_atom_level, level, &retval);
      }
    }
    return retval;
  }

  MarkdownInfo::~MarkdownInfo() {
  }
}
