#include "erl_nif.h"
#include "document.h"
#include "buffer.h"

#include <string>
#include <cstring>
#include <cstdlib>
#include <vector>

#include "markdown_info.hpp"

typedef hoedown_renderer markdown_analyzer;

static void gb_markdown_blockcode(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_buffer *lang, const hoedown_renderer_data *data);
static void gb_markdown_header(hoedown_buffer *ob, const hoedown_buffer *content, int level, const hoedown_renderer_data *data);
// void gb_markdown_list(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_list_flags flags, const hoedown_renderer_data *data);
// void gb_markdown_listitem(hoedown_buffer *ob, const hoedown_buffer *content, hoedown_list_flags flags, const hoedown_renderer_data *data);
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

#define GB_HOEDOWN_EXTENSIONS (hoedown_extensions) (HOEDOWN_EXT_DISABLE_INDENTED_CODE | HOEDOWN_EXT_SPACE_HEADERS | HOEDOWN_EXT_MATH_EXPLICIT)
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
    analyzer->opaque = (void *) new std::vector<greenbar::MarkdownInfo*>();
    return analyzer;
  }

  hoedown_document* new_hoedown_document(markdown_analyzer* renderer) {
    return hoedown_document_new(renderer, (hoedown_extensions) 0, GB_MAX_NESTING);
  }

  void free_markdown_analyzer(markdown_analyzer* analyzer) {
    if (analyzer->opaque != NULL) {
      auto collector = (std::vector<greenbar::MarkdownInfo*>*) analyzer->opaque;
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


static void gb_markdown_blockcode(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_buffer *lang,
                                  const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_FIXED_WIDTH, text));
}

static void gb_markdown_header(hoedown_buffer *ob, const hoedown_buffer *content, int level,
                                    const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_HEADER, content, level));
}

static void gb_markdown_paragraph(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  if (content->size > 0) {
    auto collector = get_collector(data);
    collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_TEXT, content));
    collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_EOL));
    collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_EOL));
  }

}

static int gb_markdown_autolink(hoedown_buffer *ob, const hoedown_buffer *link, hoedown_autolink_type type, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_TEXT, link));
  return 1;
}

static int gb_markdown_codespan(hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_FIXED_WIDTH, text));
  return 1;
}

static int gb_markdown_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_ITALICS, content));
  return 1;
}

static int gb_markdown_double_emphasis(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_BOLD, content));
  return 1;
}

static int gb_markdown_linebreak(hoedown_buffer *ob, const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_EOL));
  return 1;
}
static int gb_markdown_link(hoedown_buffer *ob, const hoedown_buffer *content, const hoedown_buffer *link, const hoedown_buffer *title,
                            const hoedown_renderer_data *data) {
  auto collector = get_collector(data);
  collector->push_back(new greenbar::MarkdownInfo(greenbar::MD_LINK, link));
  return 1;
}
