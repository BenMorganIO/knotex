defmodule Knot do
  @moduledoc """
  Supervises and manages a node.

  A node is composed of different parts:
  - A logic GenServer which coordinates everything (See `Knot.Logic`).
  - A listener which role is to handle incoming connections and be the
    acceptor (see `Knot.Listener`).
  - A supervisor in charge of the client processes (See `Knot.Client`).
  """

  use Supervisor
  alias __MODULE__, as: Knot
  alias Knot.Via
  import Knot.SofoSupervisor.Spec

  @type      t :: Via.t
  @type socket :: :gen_tcp.socket

  defmodule Handle do
    @moduledoc false
    @typedoc "Represent a running node handle."
    @type t :: %Handle{
             uri: URI.t,
            node: Knot.t,
         clients: Via.t,
      connectors: Via.t,
           logic: Logic.t,
        listener: Listener.t
    }
    defstruct [
             uri: nil,
            node: nil,
         clients: nil,
      connectors: nil,
           logic: nil,
        listener: nil
    ]
  end

  # Public API.

  @spec start(URI.t | String.t, Block.t) :: Handle.t
  def start(uri_or_address, block) do
    uri = URI.parse uri_or_address
    case Supervisor.start_child Knot.Knots, [uri, block] do
      {:ok, _}                        -> make_handle uri
      {:error, {:already_started, _}} -> make_handle uri
                            otherwise -> otherwise
    end
  end

  @spec stop(URI.t | String.t | Handle.t) :: :ok
  def stop(%Handle{uri: uri}) do
    stop uri
  end
  def stop(uri_or_address) do
    uri = URI.parse uri_or_address
    [{pid, _}] = Registry.lookup(Via.registry(), Via.id(uri, "node"))
    Supervisor.terminate_child Knot.Knots, pid
  end

  @spec start_link(URI.t | String.t, Block.t) :: {:ok, pid}
  def start_link(uri_or_address, block) do
    uri = URI.parse uri_or_address
    Supervisor.start_link Knot, {uri, block}, name: Via.node(uri)
  end

  # Supervisor callbacks.

  @spec init({URI.t, Block.t}) :: {:ok, {:supervisor.sup_flags, [:supervisor.child_spec]}}
  def init({uri, genesis}) do
    children = [
      sofo(Via.clients(uri), Knot.Client),
      sofo(Via.connectors(uri), Knot.Client.Connector),
      worker(Knot.Logic, [uri, genesis]),
      worker(Knot.Listener, [uri, Via.logic(uri)])
    ]
    supervise children, strategy: :one_for_one
  end

  # Implementation.

  @spec make_handle(URI.t | String.t) :: Handle.t
  def make_handle(uri_or_address) do
    uri = URI.parse uri_or_address
    %Handle{uri: uri,
            node: Via.node(uri),
         clients: Via.clients(uri),
      connectors: Via.connectors(uri),
           logic: Via.logic(uri),
        listener: Via.listener(uri)}
  end
end
