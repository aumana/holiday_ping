-module(users_login_SUITE).
-include_lib("common_test/include/ct.hrl").

-compile(export_all).

all() ->
    [login_with_valid_user,
     fail_login_on_unknown_user,
     fail_login_on_wrong_password].

init_per_suite(Config) ->
    {ok, _Apps} = application:ensure_all_started(holiday_ping),

    Email = test_utils:unique_email(),
    Password = <<"S3cr3t!!">>,
    Body = #{
      email => Email,
      name => <<"John Doe">>,
      password => Password,
      country => <<"argentina">>
     },
    {ok, 201, _, _} = test_utils:api_request(post, public, "/api/users", Body),

    [{user, Email}, {password, Password} | Config].

end_per_suite(Config) ->
    ok = application:stop(holiday_ping),
    ok = application:unload(holiday_ping),

    %% FIXME delete user via API, not db
    ok = db_user:delete(?config(user, Config)).

login_with_valid_user(Config) ->
    Options = [{basic_auth, {?config(user, Config), ?config(password, Config)}}],

    {ok, 200, _, #{<<"access_token">> := Token}} =
        test_utils:api_request(get, public, "/api/auth/token", <<"">>, Options),
    {ok, 200, _, _} = test_utils:api_request(get, Token, "/api/channels"),

    ok.

fail_login_on_unknown_user(Config) ->
    Options = [{basic_auth, {<<"missing@example.com">>, ?config(password, Config)}}],
    {ok, 401, _, _} =
        test_utils:api_request(get, public, "/api/auth/token", <<"">>, Options),
    ok.

fail_login_on_wrong_password(Config) ->
    Options = [{basic_auth, {?config(user, Config), <<"wrong">>}}],
    {ok, 401, _, _} =
        test_utils:api_request(get, public, "/api/auth/token", <<"">>, Options),
    ok.
