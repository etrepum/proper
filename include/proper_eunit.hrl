-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").
%%------------------------------------------------------------------------------
%% Enable the PropEr eunit integration
%%------------------------------------------------------------------------------
-ifndef(PROPER_NOEUNIT).
-ifdef(TEST).
-ifndef(PROPER_EUNIT_OPTS).
-define(PROPER_EUNIT_OPTS, []).
-endif.
proper_eunit_module_test_() ->
    proper_eunit:module(?PROPER_EUNIT_OPTS, ?MODULE).

proper_eunit_check_specs_test_() ->
    proper_eunit:check_specs(?PROPER_EUNIT_OPTS, ?MODULE).
-endif.
-endif.
