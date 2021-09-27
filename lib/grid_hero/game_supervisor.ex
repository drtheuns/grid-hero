defmodule GridHero.GameSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(opts) do
    DynamicSupervisor.start_child(__MODULE__, {GridHero.Game, opts})
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
