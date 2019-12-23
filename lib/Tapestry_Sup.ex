defmodule Tapestry.Sup do
  # Supervisor creates workers for every unique node ID and maintains an updated state during peer to peer 
  # Tapestry message passing 		
  use Supervisor

  def start_link(mapNodes) do
    Supervisor.start_link(__MODULE__, mapNodes)
  end

  def init(mapNodes) do
    keys_list = Map.keys(mapNodes)
    numRequests = Map.get(mapNodes, "req")
    keys_list = keys_list -- ["req"]
    children = Enum.map(keys_list, fn(node_id) ->
      worker(Nodes, [[node_id] ++[numRequests] ++ Map.get(mapNodes,node_id) ++ [keys_list]], [id: node_id, restart: :permanent])
    end)

    supervise(children, strategy: :one_for_one, name: Supervise_topology)
  end
end

defmodule Nodes do
  use GenServer

  def start_link(list) do
    GenServer.start_link(__MODULE__, list)
  end

  def init(stack) do
    {:ok, stack}
  end

  def print(pid) do
    GenServer.call(pid, :disp)
  end

  def send_msg(pid,hops) do
  	# Initiates message passing from current node
    GenServer.cast(pid, {:send_msg,hops})
  end

  def repeat_requests(pid) do
  	# Raises a request per second
    Process.sleep(1000)
    if Process.alive?(pid) do
    	send_msg(pid,0)
	end
  end

  def forward_msg(pid,hops,destNode) do
  	# Forwards message from current node to the destination node ID
    GenServer.cast(pid, {:forward_msg,hops,destNode})
  end
 
  def handle_call(:disp, _from, stack) do
    {:reply, stack, stack}
  end
 
  def handle_cast({:send_msg,n}, stack) do
    node_id = Enum.at(stack,0)
    nodelist = Enum.at(stack,6) -- [node_id]

    # Select a random node ID as destination
    destNode = Enum.random(nodelist)
    
    #IO.puts("destination node for #{node_id}: #{destNode}")
    numRequests = Enum.at(stack,1) 
    
    g_digit = destNode |> String.split("", trim: true)
    digit = Enum.at(g_digit,n)
    d = TapestrySimulator.Implementation.getIndex(digit)
    row = Enum.at(stack,n+2)
    e = Enum.at(row,d)
    #IO.puts("dest: #{destNode}, in #{node_id}, hops #{n}, d #{d}, e value #{e}, row #{Enum.join(row,"")}" )
    e = if e == "0" do
        tail = if d>0 do
                [head|tail] = Enum.chunk_every(row,d) 
                List.flatten(tail ++ head)
               else
                List.flatten(row)
               end
        e = Enum.reduce_while(tail, 0, fn x,acc ->
        if x != "0", do: {:halt,x}, else: {:cont, acc+0}
        end)
        e 
      else
        e 
      end
    nextNode = if Storepid.get_pid(e) == "kill" do
                    nodelist_bkptr = Storebkptr.get_ptr(e)
                    bkptr = Enum.filter(nodelist_bkptr, fn(x) -> if Storepid.get_pid(x) != "kill" do x end end)
                    # Find the suitable replacement node, matching maximum prefix from the set of backpointers
                    # forward message to the replacement node in case of intermediate node failure
                    replacement_ptr = TapestrySimulator.Implementation.findRootNode(bkptr, e)
                    replacement_ptr
                  else
                    e
                  end
    nextNode = "#{nextNode}"
    nextPid = Storepid.get_pid(nextNode)
    #IO.puts("forward to: #{nextNode}: #{destNode} and hops #{n}")
    Nodes.forward_msg(nextPid, n+1, destNode)

    # Update requests accomplished
    numRequests = numRequests - 1
    stack = List.delete_at(stack,1)
    stack = List.insert_at(stack,1,numRequests)
    if numRequests > 0 do
      repeat_requests(self())
    end
    {:noreply, stack}
  end

  def handle_cast({:forward_msg,n,destNode}, stack) do
    node_id = Enum.at(stack,0)
    #IO.puts("Node in forwarding path: Dest: #{destNode} hops: #{n} current node: #{node_id}") 
    if node_id == destNode do
    # Save hop count upon reaching destination	
      Dispstore.save_node(n)
      #IO.puts("Reached node in #{n} hops")
    else
      if n < 4 do
        g_digit = destNode |> String.split("", trim: true)
        digit = Enum.at(g_digit,n)
        d = TapestrySimulator.Implementation.getIndex(digit)
        row = Enum.at(stack,n+2)  
        e = Enum.at(row,d)  
        e = if e == "0" do
            tail = if d>0 do
                    [head|tail] = Enum.chunk_every(row,d) 
                    List.flatten(tail ++ head)
                   else
                    List.flatten(row)
                   end
            e = Enum.reduce_while(tail, 0, fn x,acc ->
            if x != "0", do: {:halt,x}, else: {:cont, acc+0}
            end)
            e
          else
            e
          end
        nextNode = if Storepid.get_pid(e) == "kill" do
                    nodelist_bkptr = Storebkptr.get_ptr(e)
                    bkptr = Enum.filter(nodelist_bkptr, fn(x) -> if Storepid.get_pid(x) != "kill" do x end end)
                    # Find the suitable replacement node, matching maximum prefix from the set of backpointers
                    # forward message to the replacement node in case of intermediate node failure
                    replacement_ptr = TapestrySimulator.Implementation.findRootNode(bkptr, e)
                    replacement_ptr
                  else
                    e
                  end

        nextPid = Storepid.get_pid(nextNode)
        Nodes.forward_msg(nextPid,n+1,destNode)
      else
      	# Store hop count as 4 in case of surrogate routing and when hops required to reach destination are 4
        Dispstore.save_node("4")
      end
    end
    {:noreply, stack}
  end
end

