%% ============================================================================
%% Rogueunlike 0.30.0
%%
%% Copyright 2010 Jeff Zellner
%%
%% This software is provided with absolutely no assurances, guarantees,
%% promises or assertions whatsoever.
%%
%% Do what thou wilt shall be the whole of the law.
%% ============================================================================

-module(ru_mobs).

-author("Jeff Zellner <jeff.zellner@gmail.com>").

-include("ru.hrl").

-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
        code_change/3]).

-export([start_link/0]).
-export([tick/0, add/1, update/1, attack/1]).

%% ============================================================================
%% Module API
%% ============================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

tick() ->
    ?CALL(tick).

add(Mob) when is_record(Mob, mob) ->
    ?CALL({add, Mob}).

update(#mob{} = Mob) ->
    ?CALL({update, Mob}).

attack(#mob{} = Mob) ->
    ?CAST({attack, Mob}).

%% ============================================================================
%% gen_server Behaviour
%% ============================================================================

init(State) ->
    {ok, State}.

handle_call(tick, _From, State) ->
    {reply, tick(State), State};
handle_call({add, Mob}, _From, State) ->
    {reply, ok, [Mob|State]};
handle_call({update, Mob}, _From, State) ->
    {reply, ok, update_mob(Mob, State)}.

handle_cast({attack, Mob}, State) ->
    attack_mob(Mob, State),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ============================================================================
%% Internal Functions
%% ============================================================================

tick([]) ->
    ok;
tick([Head | Tail] = _MobList) ->
    F = Head#mob.func,
    case F of
        nil -> ok;
        _ -> F(tick, Head)
    end,
    tick(Tail).

update_mob(Mob, State) ->
    MobRef = Mob#mob.ref,
    OtherFilter = fun(Elem) -> Elem#mob.ref =/= MobRef end,
    Others = lists:filter(OtherFilter, State),
    [Mob | Others].

attack_mob(Mob, []) ->
    ok;
attack_mob(Mob, [Head | Tail]) ->
    Ref = Mob#mob.ref,
    case Head#mob.ref of
        Ref ->
            case Head#mob.func of
                nil -> ok;
                F -> F(attack, Head)
            end;
        _ ->
            attack_mob(Mob, Tail)
    end.
