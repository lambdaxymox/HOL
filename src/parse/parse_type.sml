structure parse_type :> parse_type =
struct

open type_tokens type_grammar HOLgrammars

open qbuf

exception InternalFailure of locn.locn

val ERR = Feedback.mk_HOL_ERR "Parse" "parse_type"
val ERRloc = Feedback.mk_HOL_ERRloc "Parse" "parse_type"

fun totalify f x = SOME (f x) handle InternalFailure _ => NONE

fun parse_type tyfns allow_unknown_suffixes G = let
  val G = rules G and abbrevs = abbreviations G
  val {vartype = pVartype, tyop = pType, antiq = pAQ, qtyop} = tyfns
  fun structure_to_value0 (s,locn) args st =
      case st of
        TYOP {Args, Thy, Tyop} =>
        qtyop {Args = map (structure_to_value0 (s,locn) args) Args,
               Thy = Thy, Tyop = Tyop, Locn = locn}
      | PARAM n => List.nth(args, n)

  fun structure_to_value (s,locn) args st =
      if num_params st <> length args then
        raise ERRloc
                  locn
                  ("Incorrect number of arguments to abbreviated operator "^s^
                   " (expects "^Int.toString (num_params st)^")")
      else structure_to_value0 (s,locn) args st

  (* extra fails on next two definitions will effectively make the stream
     push back the unwanted token *)
  (* can't use item for these, because this would require the token type
     to be an equality type, which is icky *)
  fun is_LParen t = case t of LParen => true | _ => false
  fun is_RParen t = case t of RParen => true | _ => false
  fun is_LBracket t = case t of LBracket => true | _ => false
  fun is_RBracket t = case t of RBracket => true | _ => false
  fun is_Comma t = case t of Comma => true | _ => false
  fun itemP P fb = let
    val (adv, (t,locn)) = typetok_of fb (* TODO:KSW: use locn *)
  in
    if P t then (locn,adv()) else raise InternalFailure locn
  end

  fun many f fb = let
    fun recurse acc =
        case totalify f fb of
          NONE => List.rev acc
        | SOME i => recurse (i::acc)
  in
    recurse []
  end

  fun many1 f fb = let
    val i1 = f fb
    fun recurse acc =
        case totalify f fb of
          NONE => List.rev acc
        | SOME i => recurse (i::acc)
  in
    recurse [i1]
  end

  fun is_numeric s = let
    val lim = size s
    fun recurse n =
        n >= lim orelse (Char.isDigit (String.sub(s,n)) andalso
                         recurse (n + 1))
  in
    recurse 0
  end

  fun generate_fcpbit ((s,locn), args) = let
    val _ = null args orelse raise ERRloc locn "Number types take no arguments"
    val n = Arbnum.fromString s
    val _ = n <> Arbnum.zero orelse
            raise ERRloc locn "Zero is not a valid number type"
    fun recurse acc m =
        if m = Arbnum.one then acc
        else let
            val (q,r) = Arbnum.divmod(m,Arbnum.two)
          in
            recurse ((r = Arbnum.one) :: acc) q
          end
    fun bit b arg = qtyop {Thy = "fcp", Tyop = if b then "bit1" else "bit0",
                           Locn = locn, Args = [arg]}
    fun build acc bits =
        case bits of
          [] => acc
        | b :: rest => build (bit b acc) rest
    val one = qtyop {Thy = "one", Tyop = "one", Locn = locn, Args = []}
  in
    build one (recurse [] n)
  end

  fun apply_tyop (t,locn) args =
    case t of
      TypeIdent s => let
      in
        if is_numeric s then generate_fcpbit((s,locn), args)
        else
          case Binarymap.peek(abbrevs, s) of
            NONE => pType((s,locn),args)
          | SOME st => structure_to_value (s,locn) args st
      end
    | QTypeIdent(thy,ty) => qtyop{Thy=thy,Tyop=ty,Locn=locn,Args=args}
    | _ => raise Fail "parse_type.apply_tyop: can't happen"

  fun n_appls (ops, t) =
    case ops of
      [] => t
    | oph::opt => n_appls (opt, apply_tyop oph [t])
  fun n_appls_l ([], t) = raise Fail "parse_type.n_appls_l: can't happen"
    | n_appls_l (op1::ops, xs) = n_appls (ops, apply_tyop op1 xs)

  fun n_array_sfxs locn (sfxs, ty) = let
    fun build (sfx, base) =
        qtyop{Thy = "fcp", Tyop = "cart",Locn=locn,Args = [base, sfx]}
  in
    List.foldl build ty sfxs
  end

  fun parse_op slist fb = let
    val (adv, (t,locn)) = typetok_of fb
  in
    case t of
      TypeIdent s => if allow_unknown_suffixes orelse Lib.mem s slist then
                       (adv(); (t,locn))
                     else raise InternalFailure locn
    | QTypeIdent _ => (adv(); (t,locn))
    | _ => raise InternalFailure locn
  end

  fun parse_binop (stlist:{parse_string:string,opname:string}list) fb = let
    val (adv, (t,locn)) = typetok_of fb
    fun doit (t,locn) =
      case List.find (fn r => (#parse_string r = token_string t)) stlist of
        NONE => raise InternalFailure locn
      | SOME r => (adv(); (TypeIdent (#opname r),locn))
  in
    case t of
      TypeIdent s => doit (t,locn)
    | TypeSymbol s => doit (t,locn)
    | _ => raise InternalFailure locn
  end

  fun parse_asfx prse fb = let
    val (llocn, _) = itemP is_LBracket fb
    val ty = prse fb
    val (rlocn, _) = itemP is_RBracket fb
  in
    ty
  end

  fun parse_tuple prse fb = let
    val (llocn,_) = itemP is_LParen fb
    val ty1 = prse fb
    fun recurse acc = let
      val (adv,(t,locn)) = typetok_of fb
    in
      case t of
        RParen => (adv(); (List.rev acc,locn.between llocn locn))
      | Comma => (adv(); recurse (prse fb :: acc))
      | _ => raise InternalFailure locn
    end
  in
    recurse [ty1]
  end

  fun parse_atom fb = let
    val (adv, (t,locn)) = typetok_of fb
  in
    case t of
      TypeVar s => (adv(); pVartype (s, locn))
    | AQ x => (adv(); pAQ x)
    | TypeIdent s => (adv(); apply_tyop(t,locn) [])
                     (* should only be a number *)
    | _ => raise InternalFailure locn
  end

  fun parse_term current strm =
      case current of
        [] => parse_atom strm
      | (x::xs) => parse_rule x xs strm
  and parse_rule (r as (level, rule)) rs strm = let
    val next_level = parse_term rs
    val same_level = parse_rule r rs
  in
    case rule of
      INFIX (stlist, NONASSOC) => let
        val ty1 = next_level strm
      in
        case totalify (parse_binop stlist) strm of
          NONE => ty1
        | SOME opn => apply_tyop opn [ty1, next_level strm]
      end
    | INFIX (stlist, LEFT) => let
        val ty1 = next_level strm
        fun recurse acc =
            case totalify (parse_binop stlist) strm of
              NONE => acc
            | SOME opn => recurse (apply_tyop opn [acc, next_level strm])
      in
        recurse ty1
      end
    | INFIX (stlist, RIGHT) => let
        val ty1 = next_level strm
      in
        case totalify (parse_binop stlist) strm of
          NONE => ty1
        | SOME opn => apply_tyop opn [ty1, same_level strm]
      end
    | ARRAY_SFX => let
        val llocn = #2 (current strm)
        val ty1 = next_level strm
        val asfxs = many (parse_asfx (parse_term G)) strm
      in
        n_array_sfxs llocn (asfxs, ty1)
      end
    | SUFFIX slist => let
      in
        case totalify (parse_tuple (parse_term G)) strm of
          NONE => let
            val ty1 = let
              val op1 = parse_op slist strm
            in
              apply_tyop op1 []
            end handle InternalFailure l => next_level strm
            val ops = many (parse_op slist) strm
          in
            n_appls(ops, ty1)
          end
        | SOME (tyl,locn) => let
          in
            case (many (parse_op slist) strm) of
              [] => if length tyl <> 1 then
                      raise ERRloc locn "tuple with no suffix"
                    else
                      hd tyl
            | oplist => n_appls_l (oplist, tyl)
          end
      end
  end
in
  fn qb => parse_term G qb
     handle InternalFailure locn =>
            raise ERRloc locn
                  ("Type parsing failure with remaining input: "^
                   qbuf.toString qb)
end


end; (* struct *)
