-module(parse).
-export([parser/1,rpnMake/3,tryIt/0,compiler/2,stackConstr/3,evaluator/2,tokenise/1]).

-include_lib("eunit/include/eunit.hrl").

%%%%%%%% Run tryIt() to test all functions  in sequence %%%%%%%%
tryIt()->
    parser("(~1+2*3)").

parser(WffString)->
    TokenList=tokenise(WffString),
    io:fwrite("1a. Token List:  ~p~n",[TokenList]),

    RPNList = rpnMake(TokenList,[],[]),
    io:fwrite("1b. Reverse Polish Notation: ~p~n",[RPNList]),

    RPNEvaluation = evaluator(RPNList, []),
    io:fwrite("2.  RPN Evaluation: ~p~n",[RPNEvaluation]),

    NewStackP = stackConstr(TokenList,[],[]),
    io:fwrite("3.  Stack Progam: ~p~n",[NewStackP]),

    Evaluation = compiler(NewStackP, []),
    io:fwrite("4.  Compiler: ~p~n",[Evaluation]),
    Evaluation.

%%%%%%%% Individual functions %%%%%%%%  

tokenise([])->
    [];
tokenise([$+|Tail])->
    [{binOp,plus}|tokenise(Tail)];
tokenise([$-|Tail])->
    [{binOp,minus}|tokenise(Tail)];
tokenise([$/|Tail])->
    [{binOp,divide}|tokenise(Tail)];
tokenise([$*|Tail])->
    [{binOp,mul}|tokenise(Tail)];
tokenise([$~|Tail])->
    [{unOp,uMin}|tokenise(Tail)];
tokenise([$(|Tail]) ->
    [{brack,left}|tokenise(Tail)];
tokenise([$)|Tail]) ->
    [{brack,right}|tokenise(Tail)];
tokenise([Head|Tail]) ->
    [{num,Head-48}|tokenise(Tail)].

rpnMake([],[],Q1) ->
    Q1;
rpnMake([],[Head|Tail],Q1) ->
    Q2 = Q1 ++ [Head],
    rpnMake([],Tail,Q2);
rpnMake([{unOp,uMin},{num,Head}| Tail], S1, Q1) ->
    rpnMake(Tail,S1,Q1++[{num,-Head}]);
rpnMake([{num,Head}|Tail],S1,Q1) ->
    rpnMake(Tail,S1,Q1++[{num,Head}]);
rpnMake([{binOp,Head}|Tail],S1,Q1) ->
    S2 = [{Head}] ++ S1,
    rpnMake(Tail,S2,Q1);
rpnMake([{brack,left}|Tail],S1,Q1) ->
    S2 = [{push,left}] ++ S1,
    rpnMake(Tail,S2,Q1);
rpnMake([{brack,right}|Tail],[SH|ST],Q1) when SH /= {push,left} ->
    Q2 = Q1 ++ [SH],
    rpnMake([{brack,right}|Tail],ST,Q2);
rpnMake([{brack,right}|Tail],[SH|ST],Q1) when SH =:= {push,left} ->
    rpnMake(Tail,ST,Q1).

evaluator([],Stack) ->
    Stack;
evaluator([{num, Head}|Tail1], Stack) ->
    Stack2 = [Head] ++ Stack,
    evaluator(Tail1, Stack2);
evaluator([{plus}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 + Head1)] ++ Tail,
    evaluator(Tail1, Stack2);
evaluator([{minus}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 - Head1)] ++ Tail,
    evaluator(Tail1, Stack2);
evaluator([{divide}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 / Head1)] ++ Tail,
    evaluator(Tail1, Stack2);
evaluator([{mul}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 * Head1)] ++ Tail,
    evaluator(Tail1, Stack2).

stackConstr([],[],Q1) ->
    Q1 ++ [{pop},{ret}];
stackConstr([],[Head|Tail],Q1) ->
    Q2 = Q1 ++ [Head],
    stackConstr([],Tail,Q2);
stackConstr([{unOp,uMin},{num,Head}| Tail], S1, Q1) ->
    stackConstr(Tail,S1,Q1++[{push,-Head}]);
stackConstr([{num,Head}|Tail],S1,Q1) ->
    stackConstr(Tail,S1,Q1++[{push,Head}]);
stackConstr([{binOp,Head}|Tail],S1,Q1) ->
    S2 = [{Head}] ++ S1,
    stackConstr(Tail,S2,Q1);
stackConstr([{brack,left}|Tail],S1,Q1) ->
    S2 = [{push,left}] ++ S1,
    stackConstr(Tail,S2,Q1);
stackConstr([{brack,right}|Tail],[SH|ST],Q1) when SH /= {push,left} ->
    Q2 = Q1 ++ [SH],
    stackConstr([{brack,right}|Tail],ST,Q2);
stackConstr([{brack,right}|Tail],[SH|ST],Q1) when SH =:= {push,left} ->
    stackConstr(Tail,ST,Q1).

compiler([{_},{ret}],[H]) ->
    H;
compiler([{push, Head}|Tail1], Stack) ->
    Stack2 = [Head] ++ Stack,
    compiler(Tail1, Stack2);
compiler([{plus}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 + Head1)] ++ Tail,
    compiler(Tail1, Stack2);
compiler([{minus}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 - Head1)] ++ Tail,
    compiler(Tail1, Stack2);
compiler([{divide}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 / Head1)] ++ Tail,
    compiler(Tail1, Stack2);
compiler([{mul}|Tail1], [Head1, Head2|Tail]) ->
    Stack2 = [(Head2 * Head1)] ++ Tail,
    compiler(Tail1, Stack2).


%%%%%%%%%%%%%%% Unit tests %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

basic_test() ->
    % Token List Unit Tests
   ?assert(tokenise("(9-(6/3))") =:= [{brack,left},{num,9},{binOp,minus},{brack,left},{num,6},{binOp,divide},{num,3}, {brack,right},{brack,right}]),
   ?assert(tokenise("(1+2)") =:=  [{brack,left},{num,1},{binOp,plus},{num,2}, {brack,right}]),
   ?assert(tokenise("(~1+2)") =:=  [{brack,left},{unOp,uMin},{num,1},{binOp,plus},{num,2},{brack,right}]),
   ?assert(tokenise("(9*(6-3))") =:= [{brack,left},{num,9},{binOp,mul},{brack,left},{num,6},{binOp,minus},{num,3},{brack,right},{brack,right}]),

   % rpnMake Unit Tests
   ?assert(rpnMake([{brack,left},{num,9},{binOp,minus},{brack,left},{num,6},{binOp,divide},{num,3}, {brack,right},{brack,right}],[],[]) 
    =:= [{num,9},{num,6},{num,3},{divide},{minus}]),
   ?assert(rpnMake([{brack,left},{brack,left},{num,6},{binOp,divide},{num,3}, {brack,right},{binOp,minus},{num,9},{brack,right}],[],[]) 
    =:= [{num,6},{num,3},{divide},{num,9},{minus}]),
   ?assert(rpnMake([{brack,left},{num,4},{binOp,mul},{num,5},{binOp,mul},{brack,left},{num,6},{binOp,divide},{unOp,uMin},{num,2},{brack,right},{binOp,mul},{num,9},{brack,right}],[],[]) 
    =:= [{num,4},{num,5},{num,6},{num,-2},{divide},{num,9},{mul},{mul},{mul}]),
   ?assert(rpnMake([{brack,left},{unOp,uMin},{num,4},{binOp,mul},{brack,left},{unOp,uMin},{num,5},{binOp,mul},{brack,left},{unOp,uMin},{num,6},{binOp,mul},{unOp,uMin},{num,7},{brack,right},{brack,right},{brack,right}],[],[]) 
    =:= [{num,-4},{num,-5},{num,-6},{num,-7},{mul},{mul},{mul}]),

   % Evaluator Unit Tests
   ?assertEqual([13],evaluator([{num,9},{num,4},{plus}],[])),
   ?assertEqual([-36],evaluator([{num,9},{num,-4},{mul}],[])),
   ?assertEqual([17],evaluator([{num,9},{num,4},{num,4},{num,4},{num,4},{plus},{minus},{minus},{plus}],[])),
   ?assertEqual([-0.32142857142857145],evaluator([{num,9},{num,4},{num,4},{num,4},{num,4},{plus},{mul},{minus},{divide}],[])),

   % Stack Program Unit Tests
   ?assert(stackConstr([{brack,left},{brack,left},{num,9},{binOp,mul},{num,4},{brack,right},{binOp,divide},{num,2},{brack,right}],[],[])
    =:= [{push,9},{push,4},{mul},{push,2},{divide},{pop},{ret}]),
   ?assert(stackConstr([{brack,left},{brack,left},{num,9},{binOp,mul},{num,5},{brack,right},{binOp,divide},{unOp,uMin},{num,5},{brack,right}],[],[])
    =:=  [{push,9},{push,5},{mul},{push,-5},{divide},{pop},{ret}]),
   ?assert(stackConstr([{brack,left},{num,5},{binOp,mul},{brack,left},{num,4},{binOp,divide},{num,2},{brack,right},{binOp,mul},{brack,left},{unOp,uMin},{num,2},{binOp,mul},{num,2},{brack,right},{brack,right}],[],[])
    =:= [{push,5},{push,4},{push,2},{divide},{push,-2},{push,2},{mul},{mul},{mul},{pop},{ret}]),
   ?assert(stackConstr([{brack,left},{num,4},{binOp,mul},{brack,left},{num,4},{binOp,divide},{num,4},{brack,right},{brack,right}],[],[])
    =:= [{push,4},{push,4},{push,4},{divide},{mul},{pop},{ret}]),
   
   % Compiler Program Unit Tests
   ?assertEqual(12.0,compiler([{push,4},{push,9},{push,3},{divide},{mul},{pop},{ret}],[])),
   ?assertEqual(18.0,compiler([{push,6},{push,2},{divide},{push,2},{push,3},{push,1},{divide},{mul},{mul},{pop},{ret}],[])),
   ?assertEqual(360,compiler([{push,3},{push,4},{mul},{push,5},{mul},{push,6},{mul},{pop},{ret}],[])),
   ?assertEqual(6,compiler([{push,1},{push,2},{mul},{push,1},{plus},{push,2},{mul},{pop},{ret}],[])).


