#include "http11_parser.h"

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define LEN(AT, FPC) (FPC - buffer - parser->AT)
#define MARK(M,FPC) (parser->M = (FPC) - buffer)
#define PTR_TO(F) (buffer + parser->F)

/** Machine **/

%%{
  
  machine http_parser;

  action mark { mark = fpc; }

  action request_method {}

  action request_uri { 
    if(settings->on_url != NULL)
      settings->on_url(parser, mark, fpc -mark);
  }

  action http_version {	
  }

  action start_field { mark = fpc; }
  action write_field { 
    if(settings->on_header_field != NULL)
      settings->on_header_field(parser, mark, fpc -mark);
  }

  action start_value { mark = fpc; }
  action write_value {
    if(settings->on_header_value != NULL)
      settings->on_header_value(parser, mark, fpc -mark);
  }

  action done {
    if(settings->on_headers_complete != NULL)
      settings->on_headers_complete(parser);

    if(settings->on_message_complete != NULL)
      settings->on_message_complete(parser);

    fbreak;
  }

#### HTTP PROTOCOL GRAMMAR
# line endings
  CRLF = ("\r\n" | "\n");

# character types
  CTL = (cntrl | 127);
  safe = ("$" | "-" | "_" | ".");
  extra = ("!" | "*" | "'" | "(" | ")" | ",");
  reserved = (";" | "/" | "?" | ":" | "@" | "&" | "=" | "+");
  unsafe = (CTL | " " | "\"" | "#" | "%" | "<" | ">");
  national = any -- (alpha | digit | reserved | extra | safe | unsafe);
  unreserved = (alpha | digit | safe | extra | national);
  escape = ("%" xdigit xdigit);
  uchar = (unreserved | escape);
  pchar = (uchar | ":" | "@" | "&" | "=" | "+");
  tspecials = ("(" | ")" | "<" | ">" | "@" | "," | ";" | ":" | "\\" | "\"" | "/" | "[" | "]" | "?" | "=" | "{" | "}" | " " | "\t");

# elements
  token = (ascii -- (CTL | tspecials));

# URI schemes and absolute paths
  scheme = "http";
  absolute_uri = (scheme ":" (uchar | reserved )*);

  path = ( pchar+ ( "/" pchar* )* ) ;
  query = ( uchar | reserved )* ;
  param = ( pchar | "/" )* ;
  params = ( param ( ";" param )* ) ;
  rel_path = ( path? (";" params)? ) ("?" query)?;
  absolute_path = ( "/"+ rel_path );

  Request_URI = ( "*" | absolute_uri | absolute_path ) >mark %request_uri;
  Fragment = ( uchar | reserved )*;
  Method = (   "DELETE"         %{ parser->method = HTTP_DELETE; }
             | "GET"            %{ parser->method = HTTP_GET; }
             | "HEAD"           %{ parser->method = HTTP_HEAD; }
             | "POST"           %{ parser->method = HTTP_POST; }
             | "PUT"            %{ parser->method = HTTP_PUT; }
             | ( upper | digit | safe ){1,20}
           ) >mark %request_method;

  http_number = ( "1." ("0" | "1") ) ;
  HTTP_Version = ( "HTTP/" http_number ) >mark %http_version ;
  Request_Line = ( Method " " Request_URI ("#" Fragment){0,1} " " HTTP_Version CRLF ) ;

  field_name = ( token -- ":" )+ >start_field %write_field;

  field_value = any* >start_value %write_value;

  message_header = field_name ":" " "* field_value :> CRLF;

  Request = Request_Line ( message_header )* ( CRLF );

main := (Request) @done;

}%%

/** Data **/
%% write data;

void
ragel_http_parser_init (http_parser *parser, enum http_parser_type t)
{
  int cs = 0;
  %% write init;

  void *data = parser->data; /* preserve application data */
  memset(parser, 0, sizeof(*parser));
  parser->data = data;
  parser->type = t;
  parser->state = cs;
  parser->http_errno = 0;
}

size_t ragel_http_parser_execute (http_parser *parser,
                            const http_parser_settings *settings,
                            const char *data,
                            size_t len)
{
  int cs = parser->state;
  const char *p = data;
  const char *pe = data + len;
  const char *mark = 0;
  
  %% write exec;
  
  return p - data;
}