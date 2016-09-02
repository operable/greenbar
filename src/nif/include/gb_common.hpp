#ifndef GREENBAR_COMMON_H
#define GREENBAR_COMMON_H

typedef struct {
  ERL_NIF_TERM gb_atom_ok;
  ERL_NIF_TERM gb_atom_error;
  ERL_NIF_TERM gb_atom_out_of_memory;
  ERL_NIF_TERM gb_atom_name;
  ERL_NIF_TERM gb_atom_text;
  ERL_NIF_TERM gb_atom_newline;
  ERL_NIF_TERM gb_atom_fixed_width;
  ERL_NIF_TERM gb_atom_header;
  ERL_NIF_TERM gb_atom_italics;
  ERL_NIF_TERM gb_atom_bold;
  ERL_NIF_TERM gb_atom_link;
  ERL_NIF_TERM gb_atom_level;
  ERL_NIF_TERM gb_atom_url;
} gb_priv_s;

#endif
