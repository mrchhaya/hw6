//require "modules/pattern-matching.k"

module FUN-UNTYPED-COMMON
  imports DOMAINS-SYNTAX
  syntax Name                                      [token]
  syntax Names ::= List{Name,","}                  [klabel(exps)]
  syntax Exp ::= Int | Bool | String | Name
               | "(" Exp ")"                       [bracket]
  syntax Exps  ::= List{Exp,","}                   [strict, klabel(exps)]
  syntax Val
  syntax Exp ::= Val
  syntax Exps ::= Vals
  syntax Vals ::= List{Val,","}                    [klabel(exps)]
  syntax Bottom
  syntax Bottoms ::= List{Bottom,","}              [klabel(exps)]
  syntax Exp ::= left:
                 Exp "*" Exp                       [strict, group(arith)]
               | Exp "/" Exp                       [strict, group(arith)]
               | Exp "%" Exp                       [strict, group(arith)]
               > left:
                 Exp "+" Exp                       [strict, left, group(arith)]
               | Exp "^" Exp                       [strict, left, group(arith)]
// left attribute should not be necessary; currently a parsing bug
               | Exp "-" Exp                       [strict, prefer, group(arith)]
// the "prefer" attribute above is to not parse x-1 as x(-1)
// Due to some parsing problems, we currently cannot add unary minus:
               | "-" Exp                           [strict, group(arith)]
               > non-assoc:
                 Exp "<" Exp                       [strict, group(arith)]
               | Exp "<=" Exp                      [strict, group(arith)]
               | Exp ">" Exp                       [strict, group(arith)]
               | Exp ">=" Exp                      [strict, group(arith)]
               | Exp "==" Exp                      [strict, group(arith)]
               | Exp "!=" Exp                      [strict, group(arith)]
               > "!" Exp                           [strict, group(arith)]
               > Exp "&&" Exp                      [strict(1), left, group(arith)]
               > Exp "||" Exp                      [strict(1), left, group(arith)]
  syntax Exp ::= "if" Exp "then" Exp "else" Exp    [strict(1)]
  syntax Exp ::= "[" Exps "]"                             [strict, klabel(list)]
               | "head" [macro] | "tail" [macro] | "null?" [macro]
               | "[" Exps "|" Exp "]"
  syntax Val ::= "[" Vals "]"                             [klabel(list)]
  syntax Cons ::= "cons"
  syntax Val ::= Cons
  syntax Val ::= Cons Val                                 [klabel(apply)]
  syntax ConstructorName                         [token]
  syntax Exp ::= ConstructorName
               | ConstructorName "(" Exps ")"    [prefer, strict(2), klabel(constructor)]
  syntax Val ::= ConstructorName "(" Vals ")"    [klabel(constructor)]
  syntax Exp ::= "fun" Cases
               | Exp Exp                              [strict, left, klabel(apply)]
// NOTE: We would like eventually to also have Exp "(" Exps ")
  syntax Case  ::= Exp "->" Exp
  syntax Cases ::= List{Case, "|"}
  syntax Exp ::= "let" Bindings "in" Exp
               | "letrec" Bindings "in" Exp                 [prefer]
// The "prefer" attribute for letrec currently needed due to tool bug,
// to make sure that "letrec" is not parsed as "let rec".
  syntax Binding  ::= Exp "=" Exp
  syntax Bindings ::= List{Binding,"and"}
  syntax Exp ::= "ref"                             [macro]
               | "&" Name
               | "@" Exp                                     [strict]
               | Exp ":=" Exp                                [strict]
               | Exp ";" Exp                       [strict(1), right]
  syntax Exp ::= "try" Exp "catch" "(" Name ")" Exp [macro]
  syntax Val ::= "callcc"
  syntax Name ::= "throw" [token]
  syntax Exp ::= "datatype" Type "=" TypeCases Exp [macro]
// NOTE: In a future version of K, we want the datatype declaration
// to be a construct by itself, but that is not possible currently
// because K's parser wronly identifies the __ operation allowing
// a declaration to appear in front of an expression with the function
// application construct, giving ambiguous parsing errors.
  syntax TypeVar                        [token]
  syntax TypeVars ::= List{TypeVar,","} [klabel(types)]
  syntax TypeName [token]
  syntax Type ::= "int" | "bool" | "string"
                | Type "-->" Type                            [right]
                | "(" Type ")"                             [bracket]
                | TypeVar
                | TypeName             [klabel(TypeName), avoid]
                | Type TypeName   [klabel(Type-TypeName), symbol, macro]
                | "(" Types ")" TypeName                    [prefer]
  syntax Types ::= List{Type,","} [klabel(types)]
  syntax Types ::= TypeVars

  syntax TypeCase ::= ConstructorName
                    | ConstructorName "(" Types ")"
  syntax TypeCases ::= List{TypeCase,"|"}     [klabel(_|TypeCase_)]
  syntax priorities @__FUN-UNTYPED-COMMON
                  > apply
                  > print
                  > arith
                  > _:=__FUN-UNTYPED-COMMON
                  > let_in__FUN-UNTYPED-COMMON
                    letrec_in__FUN-UNTYPED-COMMON
                    if_then_else__FUN-UNTYPED-COMMON
                  > _;__FUN-UNTYPED-COMMON
                  > fun__FUN-UNTYPED-COMMON
                  > datatype_=___FUN-UNTYPED-COMMON

    syntax Exp ::= "print" Exp [strict, group(print)]
                |  "read"

endmodule

module FUN-UNTYPED-MACROS
  imports FUN-UNTYPED-COMMON

  syntax Name ::= "$h" [token] | "$t" [token]
  rule head => fun [$h|$t] -> $h
  rule tail => fun [$h|$t] -> $t
  rule null? => fun [.Exps] -> true | [$h|$t] -> false

  rule [E1,E2,Es:Exps|T] => [E1|[E2,Es|T]]                   [anywhere]

  rule P1 P2 -> E => P1 -> fun P2 -> E                       [anywhere]
  rule F P = E => F = fun P -> E                             [anywhere]

  syntax Name ::= "$k" [token] | "$v" [token]
  rule try E catch(X) E'
    => callcc (fun $k -> (fun throw -> E)(fun X -> $k E'))

  rule `Type-TypeName`(T:Type, Tn:TypeName) => (T) Tn

  rule datatype _T = _TCs E => E

endmodule


module FUN-UNTYPED-SYNTAX
  imports FUN-UNTYPED-COMMON
  imports BUILTIN-ID-TOKENS

  syntax Name ::= r"[a-z][_a-zA-Z0-9]*"           [token, prec(2)]
                | #LowerId                        [token]
  syntax ConstructorName ::= #UpperId             [token]
  syntax TypeVar  ::= r"['][a-z][_a-zA-Z0-9]*"    [token]
  syntax TypeName ::= Name                        [token]
endmodule

module FUN-UNTYPED
  imports FUN-UNTYPED-COMMON
  imports FUN-UNTYPED-MACROS
  imports DOMAINS
  //imports PATTERN-MATCHING

  configuration <T color="yellow">
                  <k color="green"> $PGM:Exp </k>
                  <env color="violet"> .Map </env>
                  <input stream ="stdin">.List</input>
                  <output stream="stdout"> .List </output>
                  <store color="white"> .Map </store>
                </T>

  syntax Val ::= Int | Bool | String
  syntax Vals ::= Bottoms
  syntax KResult ::= Val

  rule <k> X:Name => V ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V ...</store>

  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2 when I2 =/=K 0
  rule I1 % I2 => I1 %Int I2 when I2 =/=K 0
  rule I1 + I2 => I1 +Int I2
  rule S1 ^ S2 => S1 +String S2
  rule I1 - I2 => I1 -Int I2
  rule - I => 0 -Int I
  rule I1 < I2 => I1 <Int I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 > I2 => I1 >Int I2
  rule I1 >= I2 => I1 >=Int I2
  rule V1:Val == V2:Val => V1 ==K V2
  rule V1:Val != V2:Val => V1 =/=K V2
  rule ! T => notBool(T)
  rule true  && E => E
  rule false && _ => false
  rule true  || _ => true
  rule false || E => E

  rule if  true then E else _ => E
  rule if false then _ else E => E

  rule cons V:Val [Vs:Vals] => [V,Vs]

  syntax Val ::= ConstructorName

  syntax Val ::= closure(Map,Cases)
  rule <k> fun Cases => closure(Rho,Cases) ...</k>  <env> Rho </env>

  rule (. => getMatching(P, V)) ~> closure(_, P->_ | _) V:Val
  rule <k> matchResult(M:Map) ~> closure(Rho, _->E | _) _
           => bindMap(M) ~> E ~> setEnv(Rho') ...</k>
       <env> Rho' => Rho </env>
  rule (matchFailure => .) ~> closure(_, (_->_ | Cs:Cases => Cs)) _
//  rule <k> closure(Rho, P->E | _) V:Val
//           => bindMap(getMatching(P,V)) ~> E ~> setEnv(Rho') ...</k>
//       <env> Rho' => Rho </env>  when isMatching(P,V)
//  rule closure(_, (P->_ | Cs:Cases => Cs)) V:Val  when notBool isMatching(P,V)

  rule <k> let Bs in E
        => bindTo(names(Bs),exps(Bs)) ~> E ~> setEnv(Rho) ...</k>
       <env> Rho </env>

  rule <k> letrec Bs in E
        => bind(names(Bs))~>assignTo(names(Bs),exps(Bs))~>E~>setEnv(Rho)...</k>
       <env> Rho </env>

  rule <k> print V:Val => V ...</k>
      <output> ... .List => ListItem(V) </output>     [group(print)]

  rule <k> read => I ... </k>
      <input> ListItem(I:Int) => .List ... </input> [group(read)]

  syntax Name ::= "$x" [token]
  rule ref => fun $x -> & $x
  rule <k> & X => L ...</k>  <env>... X |-> L ...</env>
  rule <k> @ L:Int => V:Val ...</k>  <store>... L |-> V ...</store>
  rule <k> L:Int := V:Val => V ...</k>  <store>... L |-> (_=>V) ...</store>
  rule _V:Val; E => E

  syntax Val ::= cc(Map,K)
  rule <k> (callcc V:Val => V cc(Rho,K)) ~> K </k>  <env> Rho </env>
  rule <k> cc(Rho,K) V:Val ~> _ => V ~> K </k>  <env> _ => Rho </env>

  syntax KItem ::= setEnv(Map)  // TODO: get rid of env
  //rule (setEnv(_) => .) ~> setEnv(_)  [anywhere]
  rule <k> _:Val ~> (setEnv(Rho) => .) ...</k> <env> _ => Rho </env>

  syntax KItem ::= bindTo(Names,Exps)         [strict(2)]
                 | bindMap(Map)
                 | bind(Names)

  rule (. => getMatchingAux(Xs,Vs)) ~> bindTo(Xs:Names,Vs:Vals)
  rule matchResult(M:Map) ~> bindTo(_:Names, _:Vals) => bindMap(M)

  rule bindMap(.Map) => .
  rule <k> bindMap((X:Name |-> V:Val => .Map) _:Map) ...</k>
       <env> Rho => Rho[X <- !L:Int] </env>
       <store>... .Map => !L |-> V ...</store>

  rule bind(.Names) => .
  rule <k> bind(X:Name,Xs => Xs) ...</k>
       <env> Rho => Rho[X <- !_L:Int] </env>

  syntax KItem ::= assignTo(Names,Exps)  [strict(2)]

  rule <k> assignTo(.Names,.Vals) => . ...</k>
  rule <k> assignTo((X:Name,Xs => Xs),(V:Val,Vs:Vals => Vs)) ...</k>
       <env>... X |-> L ...</env>
       <store>... .Map => L |-> V ...</store>

  syntax Names ::= names(Bindings)  [function]
  rule names(.Bindings) => .Names
  rule names(X:Name=_ and Bs) => (X,names(Bs))::Names

  syntax Exps ::= exps(Bindings)  [function]
  rule exps(.Bindings) => .Exps
  rule exps(_:Name=E and Bs) => E,exps(Bs)

  /* Extra kore stuff */
  syntax KResult ::= Vals
  syntax Exps ::= Names
  syntax Names ::= Bottoms

  /* Matching */
  syntax MatchResult ::= getMatching(Exp, Val)                      [function]
                       | getMatchingAux(Exps, Vals)                 [function]
                       | mergeMatching(MatchResult, MatchResult)    [function]
                       | matchResult(Map)
                       | "matchFailure"

  rule getMatching(C:ConstructorName(Es:Exps), C(Vs:Vals)) => getMatchingAux(Es, Vs)
  rule getMatching([Es:Exps], [Vs:Vals])                   => getMatchingAux(Es, Vs)
  rule getMatching(C:ConstructorName, C) => matchResult(.Map)
  rule getMatching(B:Bool, B)            => matchResult(.Map)
  rule getMatching(I:Int, I)             => matchResult(.Map)
  rule getMatching(S:String, S)          => matchResult(.Map)
  rule getMatching(N:Name, V:Val) => matchResult(N |-> V)
  rule getMatching(_, _) => matchFailure        [owise]

  rule getMatchingAux((E:Exp, Es:Exps), (V:Val, Vs:Vals)) => mergeMatching(getMatching(E, V), getMatchingAux(Es, Vs))
  rule getMatchingAux(.Exps, .Vals)                       => matchResult(.Map)
  rule getMatchingAux(_, _) => matchFailure     [owise]

  rule mergeMatching(matchResult(M1:Map), matchResult(M2:Map)) => matchResult(M1 M2)
    requires intersectSet(keys(M1), keys(M2)) ==K .Set
  //rule mergeMatching(_, _) => matchFailure      [owsie]
  rule mergeMatching(matchResult(_:Map), matchFailure) => matchFailure
  rule mergeMatching(matchFailure, matchResult(_:Map)) => matchFailure
  rule mergeMatching(matchFailure, matchFailure)       => matchFailure

  rule getMatching([H:Exp | T:Exp], [V:Val, Vs:Vals])
    => getMatchingAux((H, T), (V, [Vs]))
endmodule