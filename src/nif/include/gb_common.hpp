#ifndef GREENBAR_COMMON_H
#define GREENBAR_COMMON_H

typedef struct {
  ERL_NIF_TERM gb_atom_ok;
  ERL_NIF_TERM gb_atom_error;
  ERL_NIF_TERM gb_atom_out_of_memory;
  ERL_NIF_TERM gb_atom_name;
  ERL_NIF_TERM gb_atom_text;
} gb_priv_s;

#endif
