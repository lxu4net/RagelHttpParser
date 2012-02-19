/*
 * parser_performance.cc
 *
 *  Created on: Feb 19, 2012
 *      Author: liangxu
 */

#include <string>
#include <gtest/gtest.h>
#include "http_parser.h"
#include "defines.h"

TEST(ParserPerformance, node_dump) {
  http_parser_settings settings_dump = {
      on_message_begin_dump,
      on_url_dump,
      on_header_field_dump,
      on_header_value_dump,
      on_headers_complete_dump,
      on_body_dump,
      on_message_complete_dump
  };

  http_parser parser;
  http_parser_init(&parser, HTTP_REQUEST);

  ASSERT_EQ(kMessage.size(),
      http_parser_execute(&parser, &settings_dump, kMessage.c_str(),
      kMessage.size()));
  printf("method: %s\n", http_method_str((http_method)parser.method));
}

TEST(ParserPerformance, node) {
  http_parser_settings settings_null = {};
  http_parser parser;
  for (uint32_t i = 0; i < kLoop; ++i) {
    http_parser_init(&parser, HTTP_REQUEST);
    http_parser_execute(&parser, &settings_null, kMessage.c_str(),
        kMessage.size());
  }
}

