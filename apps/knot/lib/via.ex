defmodule Via do
  @moduledoc """
  Helps building `Registry` based process names.
  """
  alias __MODULE__, as: Via
  alias Knot.{Logic, Listener}

  @registry Knot.Registry

  @type id :: {String.t, pos_integer, String.t}
  @type  t :: {:via, Registry, {Knot.Registry, Via.id}}

  def registry do
    @registry
  end

  @doc """
  Transforms a URI into a displayable string.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.readable
      "localhost:4001"
  """
  @spec readable(URI.t) :: String.t
  def readable(uri), do: "#{uri.host}:#{inspect uri.port}"

  @doc """
  Builds a via-tuple for a node given an URI.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.node
      {:via, Registry, {Knot.Registry, {"localhost", 4001, "node"}}}
  """
  @spec node(URI.t) :: Knot.t
  def node(uri), do: make uri, "node"

  @doc """
  Builds a via-tuple for a node logic given an URI.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.logic
      {:via, Registry, {Knot.Registry, {"localhost", 4001, "logic"}}}
  """
  @spec logic(URI.t) :: Logic.t
  def logic(uri), do: make uri, "logic"

  @doc """
  Builds a via-tuple for a node listener given an URI.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.listener
      {:via, Registry, {Knot.Registry, {"localhost", 4001, "listener"}}}
  """
  @spec listener(URI.t) :: Listener.t
  def listener(uri), do: make uri, "listener"


  @doc """
  Given an URI and a suffix, returns a via-tuple compatible with `Registry`.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.make("sup")
      {:via, Registry, {Knot.Registry, {"localhost", 4001, "sup"}}}
  """
  @spec make(URI.t, String.t) :: Via.t
  def make(uri, suffix) do
    uuid = id uri, suffix
    {:via, Registry, {@registry, uuid}}
  end

  @doc """
  Generates a per-uri unique ID that is suitable for via-tuple generation.

  ## Examples

      iex> "tcp://localhost:4001"
      iex>   |> URI.parse
      iex>   |> Via.id("node")
      {"localhost", 4001, "node"}
  """
  @spec id(URI.t, String.t) :: id
  def id(uri, suffix) do
    {uri.host, uri.port, suffix}
  end
end
