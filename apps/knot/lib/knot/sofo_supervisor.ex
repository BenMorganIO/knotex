defmodule Knot.SofoSupervisor do
  @moduledoc """
  Defines a simple one-for-one generic supervisor.

  Using `SofoSupervisor` is usually done by importing its `SofoSupervisor.Spec`
  submodule, and using it like so (eg. from your `Application` definition file):

        import SofoSupervisor.Spec

        def start(_type, _args) do
          children = [
            ...
            sofo(MyApp.WorkersSup, MyApp.Worker),
            ...
          ]
          Supervisor.start_link children, strategy: :one_for_one
        end

  This block would have started two simple one-for-one supervisor, each spawning
  different modules and registered under different names. Later on, you could
  spawn children on either one of these two supervisors, eg:

        Supervisor.start_child MyApp.WorkersSup, [arg1, arg2]
  """

  use Supervisor
  alias __MODULE__, as: SofoSupervisor

  @type t :: pid

  # Public API.

  defmodule Spec do
    @moduledoc false
    import Supervisor.Spec

    @spec sofo(Via.t, atom) :: Supervisor.Spec.t
    def sofo(name, mod) do
      supervisor SofoSupervisor, [name, mod], id: name
    end
  end

  @spec start_link(Via.t, atom) :: {:ok, SofoSupervisor.t}
  def start_link(ref, mod) do
    Supervisor.start_link __MODULE__, mod, name: ref
  end

  # Supervisor callbacks.

  @doc "Initializes a new simple one for one unbranded supervisor."
  @spec init(atom) :: {:ok, {:supervisor.sup_flags, [:supervisor.child_spec]}}
  def init(mod) do
    children = [worker(mod, [], restart: :transient)]
    supervise children, strategy: :simple_one_for_one
  end
end
