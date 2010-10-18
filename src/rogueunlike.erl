%% ============================================================================
%% Copyright 2010 Jeff Zellner
%%
%% This software is provided with absolutely no assurances, guarantees, 
%% promises or assertions whatsoever.
%%
%% Do what thou wilt shall be the whole of the law.
%% ============================================================================

-module(rogueunlike).

-author("Jeff Zellner <jeff.zellner@gmail.com>").

-behaviour(application).
-include("cecho.hrl").
-include("rogueunlike.hrl").

-export([start/2,stop/1]).
-export([go/0,die/0]).
-export([test_loop/1]).

%% ============================================================================
%% Behaviour Callbacks
%% ============================================================================

start(_,_) ->
    cecho_srv:start_link().

stop(_) ->
    ok.

%% ============================================================================
%% Module API
%% ============================================================================

go() ->
    init(),
    start_systems(),

    %% create console
    console ! {create, 2},
    
    %% set up input for running script
    input ! {mode, {rogueunlike_input, script_mode}},

    %% run the script engine
    true = register(script, spawn(?MODULE, test_loop, [test_script(test_char())])),

    wait_for_death().

die() ->
    console ! {exit, die},
    char ! {exit, die},
    input ! {exit, die},
    application:stop(rogueunlike),
    halt().

%% ============================================================================
%% Test Functions
%% ============================================================================

test_char() ->
    #cstats{
        name = "Groflehanger",
        gender = m,
        race = "Kitchen Dwarf",
        level = 3,
        gold = 1034,
        hp = 500,
        hpmax = 500,
        ac = -234}.

test_loop(Steps) ->
    receive
        {dosomething, _} ->
            case Steps of
                [Head|Rest] -> 
                    Head(),
                    test_loop(Rest);
                [] ->
                    test_loop(Steps)
            end;
        _ ->
            test_loop(Steps)
    end.

test_script(Char) ->

    NextChar = Char#cstats{hp = Char#cstats.hp - 10},
    NextChar1 = NextChar#cstats{hp = NextChar#cstats.hp - 10},
    NextChar2 = NextChar1#cstats{hp = NextChar1#cstats.hp - 50},

    Actions = [
        fun() ->
            console ! {stats, Char},
            console ! {msg, "You are in a dark maze of twisty passages, all of them alike."}
        end,

        fun() ->
            console ! {stats, NextChar},
            console ! {msg, "You hear a noise."}
        end,
   
        fun() ->
            console ! {stats, NextChar1},
            console ! {msg, "It is pitch black. You are likely to be eaten by a grue."}
        end,

        fun() ->
            console ! {msg, "Stop hitting yourself!"},
            console ! {stats, NextChar2}
        end,

        fun() ->
            console ! {stats, NextChar1},
            console ! {msg, "You quaff a healing potion and feel slammin!"}
        end,

        fun() ->
            console ! {stats, NextChar1#cstats{hp = 0}},
            console ! {msg, "Lol! It was poison! You're DEAD!!"}
        end
    ],
    Actions.


%% ============================================================================
%% Internal Functions
%% ============================================================================

wait_for_death() ->
    receive
        {exit, _} ->
            die();
        _ -> 
            wait_for_death()
    end.

init() ->
    application:start(rogueunlike),
    ok.

start_systems() ->

    true = register(console, 
        spawn(rogueunlike_menu, console_loop, [#console_state{}])),

    true = register(char,
        spawn(rogueunlike_char, char_loop, [#cstats{}])),

    true = register(input,
        spawn(rogueunlike_input, input_loop, [])),

    %% register self so we can quit
    true = register(suicide, self()),
    ok.


