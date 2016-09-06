#include "erl_nif.h"
#include "markdown_info.hpp"
#include "gb_common.hpp"

namespace greenbar {

  MarkdownParentInfo::MarkdownParentInfo(MarkdownInfoType info_type) {
    type_ = info_type;
  }

  MarkdownParentInfo::~MarkdownParentInfo() {
    for (size_t i = 0; i < children_.size(); i++) {
      delete children_.at(i);
    }
  }

  void MarkdownParentInfo::add_child(MarkdownInfo* child) {
    children_.push_back(child);
  }

  MarkdownInfoType MarkdownParentInfo::get_type() {
    return type_;
  }

  ERL_NIF_TERM MarkdownParentInfo::convert_children(ErlNifEnv *env) {
    ERL_NIF_TERM head, tail;
    tail = enif_make_list(env, 0);
    if (children_.empty()) {
      return tail;
    }
    for(size_t i = 0; i < children_.size(); i++) {
      auto child = children_.at(i);
      head = child->to_erl_term(env);
      tail = enif_make_list_cell(env, head, tail);
    }
    return tail;
  }

  ERL_NIF_TERM MarkdownParentInfo::to_erl_term(ErlNifEnv* env) {
    gb_priv_s *priv_data = (gb_priv_s*) enif_priv_data(env);
    ERL_NIF_TERM type_name = type_to_atom(this->type_, priv_data);
    ERL_NIF_TERM retval = enif_make_new_map(env);
    enif_make_map_put(env, retval, priv_data->gb_atom_name, type_name, &retval);
    ERL_NIF_TERM children = convert_children(env);
    enif_make_map_put(env, retval, priv_data->gb_atom_children, children, &retval);
    return retval;
  }
}
