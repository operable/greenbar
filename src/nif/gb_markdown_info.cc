#include "erl_nif.h"
#include "markdown_info.hpp"
#include "gb_common.hpp"

namespace greenbar {

  MarkdownInfo::MarkdownInfo(std::string info_name, const hoedown_buffer* buf) {
    name = info_name;
    text = std::string((char*) buf->data, buf->size);
    level = -1;
  }

  MarkdownInfo::MarkdownInfo(std::string info_name, const hoedown_buffer* buf, int info_level) {
    name = info_name;
    text = std::string((char*) buf->data, buf->size);
    level = info_level;
  }

  MarkdownInfo::MarkdownInfo(std::string info_name, std::string info_text) {
    name = info_name;
    text = info_text;
    level = -1;
  }

  ERL_NIF_TERM MarkdownInfo::to_erl_term(ErlNifEnv* env) {
    gb_priv_s *priv_data = (gb_priv_s*) enif_priv_data(env);
    ERL_NIF_TERM name, text;
    unsigned char* contents = enif_make_new_binary(env, this->name.size(), &name);
    memcpy(contents, this->name.c_str(), this->name.size());
    contents = enif_make_new_binary(env, this->text.size(), &text);
    memcpy(contents, this->text.c_str(), this->text.size());
    ERL_NIF_TERM retval = enif_make_new_map(env);
    enif_make_map_put(env, retval, priv_data->gb_atom_name, name, &retval);
    enif_make_map_put(env, retval, priv_data->gb_atom_text, text, &retval);
    return retval;
  }

  MarkdownInfo::~MarkdownInfo() {
  }
}
