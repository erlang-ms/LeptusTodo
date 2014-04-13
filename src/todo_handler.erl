-module(todo_handler).
-compile({parse_transform, leptus_pt}).

%% leptus callbacks
-export([init/3]).
-export([terminate/4]).

%% leptus routes
-export([get/3]).
-export([post/3]).
-export([put/3]).
-export([delete/3]).

%% includes
-include("todo_record.hrl").
-include_lib("stdlib/include/qlc.hrl").

%% @todo: add static route

%% Start
init(_Route, _Req, State) ->
	{ok, State}.

%% Main
get("/", _Req, State) ->
	{ok, Body} = dtl:render("index.html", [
		{title, <<"Todo List">>}
	]),
	{200, {html, Body}, State};

%% List
get("/todos", _Req, State) ->
   Query = fun() ->
      qlc:e(
         qlc:q(
            [X || X <- mnesia:table(todo)]
         )
      )
   end,
   {atomic, Records} = mnesia:transaction(Query),

   io:format("Todo lists: ~p~n", [Records]),

	{200, {json, [{<<"get">>,<<"todos">>}]}, State};

%% Retrieve
get("/todo/:id", _Req, State) ->
	{200, {json, [{<<"get">>,<<"todo">>}]}, State}.

%% Create
post("/todo", Req, State) ->
	Post = leptus_req:body_qs(Req),
	io:format("post: ~p~n", [Post]),

   {MegaS, S, MicroS} = erlang:now(),
   Id = list_to_binary(
      integer_to_list(MegaS) ++
      integer_to_list(S) ++
      integer_to_list(MicroS)
   ),

	{<<"content">>, Content} = lists:keyfind(<<"content">>, 1, Post),
	{<<"priority">>, Priority} = lists:keyfind(<<"priority">>, 1, Post),
	{<<"status">>, Status} = lists:keyfind(<<"status">>, 1, Post),

	Write = fun() ->
		Todo = #todo{
			id = Id,
			content = Content,
			priority = Priority,
			status = Status
		},
		mnesia:write(Todo)
	end,

	mnesia:transaction(Write),

	{200, {json, Post}, State}.

%% Update
put("/todo/:id", _Req, State) ->
	{200, {json, [{<<"put">>,<<"todo">>}]}, State}.

%% Delete
delete("/todo/:id", _Req, State) ->
	{200, {json, [{<<"delete">>,<<"todo">>}]}, State}.

%% End
terminate(_Reason, _Route, _Req, _State) ->
	ok.
