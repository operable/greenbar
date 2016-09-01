#ifndef GREENBAR_MARKDOWN_ANALYZER_H
#define GREENBAR_MARKDOWN_ANALYZER_H

#include "document.h"
#include "markdown_info.hpp"

typedef hoedown_renderer markdown_analyzer;

namespace greenbar {

  // Create a new Markdown analyzer
  markdown_analyzer* new_markdown_analyzer();

  // Free Markdown analyzer
  void free_markdown_analyzer(markdown_analyzer* analyzer);

  // Get collector associated with analyzer instance
  std::vector<greenbar::MarkdownInfo*>* get_collector(markdown_analyzer* analyzer);

  // Prepare a hoedown document for processing with specified analyzer
  hoedown_document* new_hoedown_document(markdown_analyzer* analyzer);
}

#endif
