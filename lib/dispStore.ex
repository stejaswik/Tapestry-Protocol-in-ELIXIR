# Stores hops achieved per request
defmodule Dispstore do
  use GenServer

  def start_link(stack) do
    GenServer.start_link(__MODULE__, stack, name: __MODULE__)
  end

  def init(stack) do
    {:ok, stack}
  end

  def save_node(node) do
    GenServer.cast(__MODULE__, {:savenode, [node]})
  end

  def print() do
    GenServer.call(__MODULE__, :printval) 
  end

  def handle_cast({:savenode, list}, stack) do
    # keep adding hops per request to existing state
    stack = List.flatten([list] ++ [stack])
    len = length(stack)

    # retrieve initialized convergence_rate, start_time values from stack
    convergence_rate = List.last(stack)

    # No Failure: Donot exit until 100% convergence is achieved [nodes*requests per peer]
    # Failure: Donot exit until 100% convergence is achieved [(nodes - failed nodes)*requests per peer]
    # A factor of 2 is added because the state "stack" is initialized with a 2-list
    if len >= convergence_rate+2 do
      parent_pid = Enum.at(stack, len-2)
      send(parent_pid, :work_is_done)
    end
    {:noreply, stack}
  end

  def handle_call(:printval, _from, stack) do
  	#Returns stored hops
    {:reply, stack, stack}
  end
end