structure term_grammar_dtype =
struct

open HOLgrammars
type rule_record = {term_name   : string,
                    elements    : pp_element list,
                    timestamp   : int,
                    block_style : PhraseBlockStyle * block_info,
                    paren_style : ParenStyle}

datatype binder =
         LAMBDA
       | BinderString of {tok : string, term_name : string, timestamp : int}

datatype prefix_rule =
         STD_prefix of rule_record list
       | BINDER of binder list

datatype suffix_rule =
         STD_suffix of rule_record list
       | TYPE_annotation

datatype infix_rule =
         STD_infix of rule_record list * associativity
       | RESQUAN_OP
       | VSCONS
       | FNAPP of rule_record list

type listspec =
     {separator  : pp_element list,
      leftdelim  : pp_element list,
      rightdelim : pp_element list,
      block_info : block_info,
      cons       : string,
      nilstr     : string}

datatype grammar_rule =
         PREFIX of prefix_rule
       | SUFFIX of suffix_rule
       | INFIX of infix_rule
       | CLOSEFIX of rule_record list
       | LISTRULE of listspec list

datatype fixity =
         Infix of associativity * int
       | Closefix
       | Suffix of int
       | Prefix of int
       | Binder

type grule = {term_name : string,
              fixity : fixity,
              pp_elements: pp_element list,
              paren_style : ParenStyle,
              block_style : PhraseBlockStyle * block_info}

datatype user_delta =
         GRULE of grule
       | LRULE of listspec
       | RMTMTOK of {term_name : string, tok : string}
       | RMTMNM of string


end