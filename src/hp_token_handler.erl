-module(hp_token_handler).

-export([init/3,
         allowed_methods/2,
         content_types_accepted/2,
         from_json/2]).

init(_Transport, _Req, []) ->
    {upgrade, protocol, cowboy_rest}.

allowed_methods(Req, State) ->
    {[<<"POST">>], Req, State}.

content_types_accepted(Req, State) ->
    {[{<<"application/json">>, from_json}], Req, State}.

from_json(Req, State) ->
    {ok, Body, Req2} = cowboy_req:body(Req),
    %% TODO validate required fields, password strong enough
    #{<<"email">> := Email, <<"password">> := Password} = hp_json:decode(Body),

    %% FIXME properly handle unauthorized requests
    {ok, User} = hp_user_storage:authenticate(Email, Password),
    {ok, Token} = hp_auth_tokens:encode(User),

    %% TODO make sure setting response actually works for POST requests
    Response = hp_json:encode(#{access_token => Token}),
    Req3 = cowboy_req:set_resp_body(Response, Req2),
    {true, Req3, State}.
