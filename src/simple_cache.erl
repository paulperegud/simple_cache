%%% @doc Main module for simple_cache.
%%%
%%% Copyright 2013 Marcelo Gornstein &lt;marcelog@@gmail.com&gt;
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%% @end
%%% @copyright Marcelo Gornstein <marcelog@gmail.com>
%%% @author Marcelo Gornstein <marcelog@gmail.com>
%%%
-module(simple_cache).
-author('marcelog@gmail.com').

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Types.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ETS_TID, atom_to_list(?MODULE)).
%% -define(NAME(N), list_to_atom(?ETS_TID ++ "_" ++ atom_to_list(N))).
-define(NAME(N), N).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Exports.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Public API.
-export([start/0]).
-export([init/1]).
-export([get/2, set/4]).
-export([flush/1, flush/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Public API.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% @doc start the application
start() ->
    application:start(simple_cache, permanent).

%% @doc Initializes a cache. Note that when 
%% caller is terminated, cache is destroyed.
-spec init(atom()) -> ok.
init(CacheName) ->
  RealName = ?NAME(CacheName),
  RealName = ets:new(RealName, [
    named_table, {read_concurrency, true}, public, {write_concurrency, true}
  ]),
  ok.

%% @doc Deletes the keys that match the given ets:matchspec() from the cache.
-spec flush(atom(), term()) -> true.
flush(CacheName, Key) ->
  RealName = ?NAME(CacheName),
  ets:delete(RealName, Key).

%% @doc Deletes all keys in the given cache.
-spec flush(atom()) -> true.
flush(CacheName) ->
  RealName = ?NAME(CacheName),
  true = ets:delete_all_objects(RealName).

%% @doc Tries to lookup Key in the cache, and execute the given FunResult
%% on a miss.
-spec get(atom(), term()) -> {ok, term()} | {error, not_found}.
get(CacheName, Key) ->
  RealName = ?NAME(CacheName),
  case ets:lookup(RealName, Key) of
      [] ->
	  {error, not_found};
      [{Key, R}] -> 
	  R % Found, return the value.
  end.

-spec set(atom(), term(), term(), infinity|pos_integer()) -> {ok, term()} | {error, not_found}.
set(CacheName, Key, Value, LifeTime) ->
    RealName = ?NAME(CacheName),
    ets:insert(RealName, {Key, Value}),
    erlang:send_after(
      LifeTime, simple_cache_expirer, {expire, CacheName, Key}
     ),
    ok.
