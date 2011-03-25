%%% Copyright 2010 Manolis Papadakis (manopapad@gmail.com)
%%%            and Kostis Sagonas (kostis@cs.ntua.gr)
%%%
%%% This file is part of PropEr.
%%%
%%% PropEr is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% (at your option) any later version.
%%%
%%% PropEr is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with PropEr.  If not, see <http://www.gnu.org/licenses/>.

%%% @author Bob Ippolito <bob@redivi.com>
%%% @copyright 2010 Manolis Papadakis and Kostis Sagonas
%%% @version {@version}
%%% @doc This is the main PropEr module.

-module(proper_eunit).

-export([module/2, check_specs/2]).

-spec module([term()], atom()) -> [term()].
module(UserOpts, Mod) ->
    call_proper(UserOpts, Mod, fun proper:module/2).

-spec check_specs([term()], atom()) -> [term()].
check_specs(UserOpts, Mod) ->
    call_proper(UserOpts, Mod,
                %% Inconsistent with proper:module/2
                fun (Opts, M) -> proper:check_specs(M, Opts) end).

read_tests([]) ->
    [];
read_tests([{"Testing ~w:~w/~b~n", [M,F,A]} | Rest]) ->
    {Test, Rest1} = read_one_test(Rest),
    [{lists:flatten(io_lib:format("~w:~w/~b", [M,F,A])),
      fun () -> test_fun({M,F,A}, Test) end} | read_tests(Rest1)].

test_fun(_MFA, ok) ->
    ok;
test_fun({M,F,_A}, {error, Args}) ->
    ArgString = string:join([io_lib:format("~p", [Arg]) || Arg <- Args], ","),
    Expr = lists:flatten(io_lib:format("~w:~w(~s)", [M, F, ArgString])),
    erlang:error({assertion_failed,
                  [{module, M},
                   {line, ?LINE},
                   {expression, Expr},
                   {expected, true},
                   {value, false}]}).

read_one_test([{"OK: Passed ~b test(s).~n", [_Num]} | Rest]) ->
    {ok, Rest};
read_one_test([{"Failed: After ~b test(s).~n", [_Num]},
               {"~w~n", [_FirstFail]},
               {"(~b time(s))~n",[_ShrinkNum]},
               {"~w~n", [ShrinkFail]} | Rest]) ->
    {{error, ShrinkFail}, Rest}.

call_proper(UserOpts, Mod, Fun) ->
    {Output, Collect} = new_ets_output(),
    Fun([{on_output, Output} | UserOpts], Mod),
    read_tests(Collect()).

new_ets_output() ->
    T = ets:new(tmp_proper_output, [ordered_set, public]),
    {fun (_Fmt, []) ->
             %% If it's static text, it's not interesting.
             ok;
         (Fmt, Args) ->
             ets:insert_new(T, {now(), {Fmt, Args}})
     end,
     fun () ->
             R = ets:select(T, [{{'$1','$2'},[],['$2']}]),
             ets:delete(T),
             R
     end}.
