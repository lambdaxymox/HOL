val _ = use "poly-stdprefix.ML";

fun useB f =
  (use (f ^ ".sig");
   use (f ^ ".sml"));

val _ = useB "Database";
val _ = use "HOLPage.sml";
val _ = useB "Htmlsigs";
val _ = useB "ParseDoc";
val _ = use "Keepers.sml";
val _ = use "Asynt.sml";

fun u f = use ("../../tools/mlyacc/mlyacclib/" ^ f ^ ".sml");
val _ = u "MLY_base-sig";
val _ = u "MLY_join";
val _ = u "MLY_lrtable";
val _ = u "MLY_stream";
val _ = u "MLY_parser2";


val _ = useB "Parser.grm";

(* I think there's a bug in the lexer generator, but I don't want to fix it
 * beause I don't know if that will break it on mosml.  CharVector.foldl is used
 * only for lexers with %count *)

structure CharVector = struct
open CharVector
fun foldl f b vs =
  CharVectorSlice.foldli f b  (CharVectorSlice.slice vs)
end;

val _ = use "Lexer.lex.sml";
val _ = use "Parsspec.sml";
val _ = use "Printbase.sml";
val _ = useB "../../sigobj/Systeml";

val _ = use "makebase.sml";

val main = makebase.main
