# Stores a map in its state, keys constitute the node IDS 
# and values consistitute list of backpointers
defmodule Storebkptr do
  use GenServer

  def start_link(nodebptr) do
    GenServer.start_link(__MODULE__, nodebptr, name: __MODULE__)
  end

  def init(nodebptr) do
    {:ok, nodebptr}
  end

  def get_ptr(node) do
    GenServer.call(__MODULE__, {:getptr, node})
  end

  def handle_call({:getptr, node}, _from, nodebptr) do
    node = to_string(node)
    bkptr = Map.get(nodebptr, node)
    {:reply, bkptr, nodebptr}
  end
end