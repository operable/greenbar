#include "erl_nif.h"
#include "document.h"
#include "buffer.h"

#include <string>
#include <iostream>
#include <cstring>
#include <cstdlib>
#include <vector>

#include "markdown_info.hpp"

typedef hoedown_renderer markdown_analyzer;

static void gb_markdown_blockcode(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_buffer *lang, const hoedown_renderer_data *data);
static void gb_markdown_header(hoedown_buffer *ob, const hoedown_buffer *content, int level, const hoedown_renderer_data *data);
static void gb_markdown_list(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_list_flags flags, const hoedown_renderer_data *data);
static void gb_markdown_listitem(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_list_flags flags, const hoedown_renderer_data *data);
static void gb_markdown_paragraph(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
// void gb_markdown_table(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
// void gb_markdown_table_header(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
// void gb_markdown_table_body(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
// void gb_markdown_table_row(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
// void gb_markdown_table_cell(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_table_flags flags, const hoedown_renderer_data *data);

static int gb_markdown_autolink(hoedown_buffer *ob, const hoedown_buffer *link, hoedown_autolink_type type, const hoedown_renderer_data *data);
static int gb_markdown_codespan(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_renderer_data *data);
static int gb_markdown_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
static int gb_markdown_double_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data);
static int gb_markdown_linebreak(hoedown_buffer *ob, const hoedown_renderer_data *data);
static int gb_markdown_link(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_buffer *link, const hoedown_buffer *title,
                     const hoedown_renderer_data *data);
static void gb_markdown_normal_text(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_renderer_data *data);

#define GB_HOEDOWN_EXTENSIONS (hoedown_extensions) (HOEDOWN_EXT_DISABLE_INDENTED_CODE | HOEDOWN_EXT_SPACE_HEADERS | \
                                                    HOEDOWN_EXT_MATH_EXPLICIT | HOEDOWN_EXT_NO_INTRA_EMPHASIS)
#define GB_MAX_NESTING 4

namespace greenbar {

  markdown_analyzer* new_markdown_analyzer() {
    // Create renderer
    auto analyzer = (markdown_analyzer *) malloc(sizeof(markdown_analyzer));
    if (!analyzer) {
      return NULL;
    }
    // Zero out all fields
    memset(analyzer, 0, sizeof(markdown_analyzer));

    // Block callbacks
    analyzer->blockcode = gb_markdown_blockcode;
    analyzer->paragraph = gb_markdown_paragraph;
    analyzer->header = gb_markdown_header;

    // Span callbacks
    analyzer->codespan = gb_markdown_codespan;
    analyzer->emphasis = gb_markdown_emphasis;
    analyzer->double_emphasis = gb_markdown_double_emphasis;
    analyzer->triple_emphasis = gb_markdown_double_emphasis;
    analyzer->autolink = gb_markdown_autolink;
    analyzer->link = gb_markdown_link;
    analyzer->linebreak = gb_markdown_linebreak;
    analyzer->list = gb_markdown_list;
    analyzer->listitem = gb_markdown_listitem;
    analyzer->normal_text = gb_markdown_normal_text;
    analyzer->opaque = (void *) new std::vector<greenbar::MarkdownInfo*>();
    return analyzer;
  }

  hoedown_document* new_hoedown_document(markdown_analyzer* renderer) {
    return hoedown_document_new(renderer, (hoedown_extensions) GB_HOEDOWN_EXTENSIONS, GB_MAX_NESTING);
  }

  void free_markdown_analyzer(markdown_analyzer* analyzer) {
    if (analyzer->opaque != NULL) {
      auto collector = (std::vector<greenbar::MarkdownInfo*>*) analyzer->opaque;
      for (size_t i = 0; i < collector->size(); i++) {
        delete collector->at(i);
      }
      delete collector;
    }
    free(analyzer);
  }

  std::vector<greenbar::MarkdownInfo*>* get_collector(markdown_analyzer* analyzer) {
    return (std::vector<greenbar::MarkdownInfo*>*) analyzer->opaque;
  }

}

static std::vector<greenbar::MarkdownInfo*>* get_collector(const hoedown_renderer_data *data) {
  return (std::vector<greenbar::MarkdownInfo*>*) data->opaque;
}


static bool set_previous(const hoedown_renderer_data *data, greenbar::MarkdownInfoType previousType, greenbar::MarkdownInfoType newType) {
  bool retval = false;
  auto collector = get_collector(data);
  if (!collector->empty()) {
    auto last_info = greenbar::as_leaf(collector->back());
    if (last_info != nullptr && last_info->get_type() == previousType) {
      last_info->set_type(newType);
      retval = true;
    }
  }
  return retval;
}

static bool set_previous(const hoedown_renderer_data *data, greenbar::MarkdownInfoType previousType, greenbar::MarkdownInfoType newType,
                         int level) {
  bool retval = false;
  auto collector = get_collector(data);
  if (!collector->empty()) {
    auto last_info = greenbar::as_leaf(collector->back());
    if (last_info != nullptr && last_info->get_type() == previousType) {
      last_info->set_type(newType);
      last_info->set_level(level);
      retval = true;
    }
  }
  return true;
}

static void gb_markdown_blockcode(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_buffer *lang,
                                  const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(greenbar::new_leaf(greenbar::MD_FIXED_WIDTH, text));
}

static void gb_markdown_header(hoedown_buffer *ob, const hoedown_buffer *content, int level,
                               const hoedown_renderer_data *data) {
  if (content->size == 0) {
    set_previous(data, greenbar::MD_TEXT, greenbar::MD_HEADER, level);
  } else {
    auto collector = get_collector(data);
    collector->push_back(greenbar::new_leaf(greenbar::MD_HEADER, content, level));
  }
}

static void gb_markdown_paragraph(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownLeafInfo(greenbar::MD_EOL));
  switch(content->size) {
    // If content == "" return
  case 0:
    return;
    // If content == "\n" return
    // else fall through to default case
  case 1:
    if (memcmp(content->data, "\n", 1) == 0) {
      return;
    }
    // Add text and EOL node
  default:
    collector->push_back(greenbar::new_leaf(greenbar::MD_TEXT, content));
    collector->push_back(new greenbar::MarkdownLeafInfo(greenbar::MD_EOL));
  }
}

static int gb_markdown_autolink(hoedown_buffer *ob, const hoedown_buffer *link, hoedown_autolink_type type, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(greenbar::new_leaf(greenbar::MD_TEXT, link));
  return 1;
}

static int gb_markdown_codespan(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(greenbar::new_leaf(greenbar::MD_FIXED_WIDTH, text));
  return 1;
}

static int gb_markdown_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  if (content->size == 0) {
    set_previous(data, greenbar::MD_TEXT, greenbar::MD_ITALICS);
  } else {
    auto collector = get_collector(data);
    collector->push_back(greenbar::new_leaf(greenbar::MD_ITALICS, content));
  }
  return 1;
}

static int gb_markdown_double_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  if (content->size == 0) {
    set_previous(data, greenbar::MD_TEXT, greenbar::MD_BOLD);
  } else {
    auto collector = get_collector(data);
    collector->push_back(greenbar::new_leaf(greenbar::MD_BOLD, content));
  }
  return 1;
}

static int gb_markdown_linebreak(hoedown_buffer *ob, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownLeafInfo(greenbar::MD_EOL));
  return 1;
}

static int gb_markdown_link(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_buffer *link, const hoedown_buffer *title,
                            const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  if (collector->empty()) {
    collector->push_back(greenbar::new_leaf(greenbar::MD_LINK, title, link));
  } else {
    auto last_info = greenbar::as_leaf(collector->back());
    if (last_info != nullptr && last_info->get_type() == greenbar::MD_TEXT) {
      last_info->set_type(greenbar::MD_LINK);
      last_info->set_url(std::string((char*)link->data, link->size));
    } else {
      collector->push_back(greenbar::new_leaf(greenbar::MD_LINK, title, link));
    }
  }
  return 1;
}

static void gb_markdown_normal_text(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  switch(text->size) {
  case 0:
    break;
  case 1:
    if (memcmp(text->data, "\n", 1) == 0) {
      collector->push_back(new greenbar::MarkdownLeafInfo(greenbar::MD_EOL));
      break;
    }
  default:
    collector->push_back(greenbar::new_leaf(greenbar::MD_TEXT, text));
    break;
  }
}

static void gb_markdown_list(hoedown_buffer *ob, const hoedown_buffer *content,
                             hoedown_list_flags flags, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  if (collector->empty()) {
    return;
  }
  auto list_type = greenbar::MD_UNORDERED_LIST;
  if (flags & HOEDOWN_LIST_ORDERED) {
    list_type = greenbar::MD_ORDERED_LIST;
  }
  auto item = new greenbar::MarkdownParentInfo(list_type);
  auto child = collector->back();
  while (child->get_type() == greenbar::MD_LIST_ITEM) {
    collector->pop_back();
    item->add_child(child);
    if (collector->empty()) {
      break;
    }
    child = collector->back();
  }
  collector->push_back(item);
}

static void gb_markdown_listitem(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_list_flags flags, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  if (collector->empty()) {
    return;
  }
  auto item = new greenbar::MarkdownParentInfo(greenbar::MD_LIST_ITEM);
  auto child = collector->back();
  if (child->get_type() == greenbar::MD_EOL) {
    collector->pop_back();
    item->add_child(child);
    while (true) {
      if(collector->empty()) {
        break;
      }
      child = collector->back();
      if (child->get_type() == greenbar::MD_ORDERED_LIST || child->get_type() == greenbar::MD_UNORDERED_LIST ||
          child->get_type() == greenbar::MD_LIST_ITEM) {
        break;
      }
      collector->pop_back();
      item->add_child(child);
    }
  }
  collector->push_back(item);
}
