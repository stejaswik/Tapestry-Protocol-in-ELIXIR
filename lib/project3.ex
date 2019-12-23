defmodule TapestrySimulator.Implementation do
  
  def tapestry(numNodes,numRequests) do
  	# Returns a map consisting of unique nodes and their routing tables
    map_set = MapSet.new
    map_set = generate_nodes(numNodes,map_set)
    nodelist = MapSet.to_list(map_set)
    dyn_insert_node = Enum.take(nodelist, -1)
    nodelist = nodelist -- dyn_insert_node
    length_nodes = length(nodelist)-1

    # Digits for node ID generation
    numbers = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]

    # List of nodes starting with the following digits are added to respective lists
    lis0 = getSimilar(nodelist, "0", 0)
    lis1 = getSimilar(nodelist, "1", 0)
    lis2 = getSimilar(nodelist, "2", 0)
    lis3 = getSimilar(nodelist, "3", 0)
    lis4 = getSimilar(nodelist, "4", 0)
    lis5 = getSimilar(nodelist, "5", 0)
    lis6 = getSimilar(nodelist, "6", 0)
    lis7 = getSimilar(nodelist, "7", 0)
    lis8 = getSimilar(nodelist, "8", 0)
    lis9 = getSimilar(nodelist, "9", 0)
    lisA = getSimilar(nodelist, "A", 0)
    lisB = getSimilar(nodelist, "B", 0)
    lisC = getSimilar(nodelist, "C", 0)
    lisD = getSimilar(nodelist, "D", 0)
    lisE = getSimilar(nodelist, "E", 0)
    lisF = getSimilar(nodelist, "F", 0)

    # List of lists, containing all the above lists
    lisAll = [lis0] ++ [lis1] ++ [lis2] ++ [lis3] ++ [lis4] ++ [lis5] ++
             [lis6] ++ [lis7] ++ [lis8] ++ [lis9] ++ [lisA] ++ [lisB] ++
             [lisC] ++ [lisD] ++ [lisE] ++ [lisF]

    # Map containing the nodes as key and routing table as value
    # in the form of list of lists for four levels
    mapNodes=%{}
    mapNodes=for x<-0..length_nodes do
        node = Enum.at(nodelist, x)
        list1 = create_L1_list(lisAll, node)
        list1 = Enum.map(list1, fn x -> if x==nil do "0" else x end end)
        list2 = create_L2_list(lisAll, node, numbers)
        list3 = create_L3_list(lisAll, node, numbers)
        list4 = create_L4_list(lisAll, node, numbers)
        # list of lists, contains routing table of node 
        list = [list1] ++ [list2] ++ [list3] ++ [list4]
        Map.put(mapNodes, node, list)
      end

    mapNodes = Enum.reduce(mapNodes, fn(x, acc) -> Map.merge(x, acc, fn _k, v1, v2 -> [v1, v2] end) end)

    # Add "dynamic" to dynamic node's value field, will be an identification for future reference
    mapNodes = Map.put(mapNodes, Enum.at(dyn_insert_node,0), "dynamic")

    # Add numRequests to the existing map and pass it as a parameter to the Supervisor
    _mapNodes = Map.put(mapNodes,"req", numRequests)
  end

  
  def node_routing_table(lisAll, node) do
  	# Generates routing table for a dynamic node during node join 
    numbers = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
    list1 = create_L1_list(lisAll, node)
    list1 = Enum.map(list1, fn x -> if x==nil do "0" else x end end)
    list2 = create_L2_list(lisAll, node, numbers)
    list3 = create_L3_list(lisAll, node, numbers)
    list4 = create_L4_list(lisAll, node, numbers)
    list = [list1] ++ [list2] ++ [list3] ++ [list4]
    list
  end

  
  def update_routing_table(routing_table, update_node, insert_node) do
   	# Returns updated routing table for given node with dynamic node's information during node join
    digits = insert_node |> String.split("", trim: true)

    row = Enum.map(0..3, fn(x) -> Enum.at(routing_table, x) end)

    val = Enum.map(0..3, fn(x) ->
      Enum.at(Enum.at(row, x), getIndex(Enum.at(digits, x)))
    end)

    node_closer = Enum.map(0..3, fn(x) ->
      value = if x == 0 and Enum.at(val,x) == update_node do
                  insert_node
              else
                if x == 0 and Enum.at(val,x) != update_node do
                  node_close(insert_node,Enum.at(val,x), update_node)
                else
                  if String.slice(insert_node,0..(x-1)) == String.slice(update_node,0..(x-1)) do
                    #IO.puts ("--------entered #{insert_node} : #{update_node}----------")
                    node_close(insert_node,Enum.at(val,x), update_node)
                  else
                    Enum.at(val,x)
                  end
                end
              end
              value
            end)

    rows = Enum.map(0..3, fn(x) ->
      r = Enum.at(row, x)
      i = getIndex(Enum.at(digits, x))
      r = List.delete_at(r, i)
      r = List.insert_at(r, i, Enum.at(node_closer, x))
      r
    end)

    rows
  end

  
  def node_close(insert_node, val, update_node) do
  	# Returns the node closer to the update_node
    _return_node = if val == "0" do
                    insert_node
                  else
                    un = update_node|> to_charlist() |> List.to_integer(16)
                    node = insert_node|> to_charlist() |> List.to_integer(16)
                    v = val|> to_charlist() |> List.to_integer(16)

                    value = case {un,node,v} do
                      {x,y,z} when abs(x-y) > abs(x-z) ->
                        val
                      _ -> insert_node
                      end
                    value
                  end
  end

  
  def generateBackpointer(map) do
  	# Generates map consisting of nodes and their backpointers
    keys_list = Map.keys(map)
    keys_list = keys_list -- ["req"]

    # Access all the nodes having "dynamic" as their values
    dyn_node = Enum.filter(keys_list, fn(x) -> if Map.get(map,x) == "dynamic" do x end end)
    keys_list = keys_list -- dyn_node

    list = Enum.map(keys_list, fn(x) ->
      l1 = List.flatten(Map.get(map, x))
      _l2 = Enum.map(l1, fn(y) -> {y,x} end)
    end)
    list = List.flatten(list)
   
    m = for x <- list do
      Enum.into([x], %{})
    end

    map_bp = Enum.reduce(m,fn(x,acc) -> Map.merge(x,acc,fn _k,v1,v2 ->
    List.flatten([v1]++[v2])
      end) end)

    map_bp = Map.delete(map_bp, "0")
    map_bp = Enum.map(map_bp, fn{k,v}-> {k, if length(v) > 1 do Enum.uniq(v) -- [k] else v end} end) |> Enum.into(%{})

    map_bp
  end

  
  def addNodeDynamically(map, map1) do
  	# Returns an updated map after adding nodes dynamically to the existing tapestry network map
    
    
    numbers = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
    # Extract key values
    keys_list = Map.keys(map)
    keys_list = keys_list -- ["req"]
    # Find out which node should be dynamically added <"dynamic">
    dyn_node = Enum.filter(keys_list, fn(x) -> if Map.get(map,x) == "dynamic" do x end end)
    keys_list = keys_list -- dyn_node

    # Find root node for the node inserted
    nodeRoot = findRootNode(keys_list, Enum.at(dyn_node,0))

    # Take root nodes routing table for the pth level <p is maximum prefix match>
    # collect backpointers for each node from level (p) of root node's routing table and remove repetitions
    # populate the levels: 0 to p using root node routing table and collected backpointers
    # populate the remaining levels: with zeros
    i = 0
    list = Enum.map(0..3, fn(x)->
          if String.at(Enum.at(dyn_node,i), x) == String.at(nodeRoot, x) do
            1
          else
            0
          end
        end)

    prefix = Enum.reduce_while(list, 0, fn x, acc ->
            if x > 0 do
              {:cont, x+acc}
            else
              {:halt, acc}
            end
          end)

    routing_table = Map.get(map, nodeRoot)
    level_neighbors = [Enum.at(routing_table, prefix)]
    _backtrack_neigh = []
    backTNodes = []

    neigh = Enum.filter(List.first(level_neighbors), fn(x) -> if x != "0" do x end end)
    backTNodes = for i <- 0..length(neigh)-1 do
                    backTNodes ++ Map.get(map1, Enum.at(neigh, i))
                  end
    backTNodes = List.flatten(backTNodes)
    backTNodes = Enum.uniq(backTNodes)
    backTNodes = backTNodes ++ [nodeRoot]

    lis0 = getSimilar(backTNodes, "0", 0)
    lis1 = getSimilar(backTNodes, "1", 0)
    lis2 = getSimilar(backTNodes, "2", 0)
    lis3 = getSimilar(backTNodes, "3", 0)
    lis4 = getSimilar(backTNodes, "4", 0)
    lis5 = getSimilar(backTNodes, "5", 0)
    lis6 = getSimilar(backTNodes, "6", 0)
    lis7 = getSimilar(backTNodes, "7", 0)
    lis8 = getSimilar(backTNodes, "8", 0)
    lis9 = getSimilar(backTNodes, "9", 0)
    lisA = getSimilar(backTNodes, "A", 0)
    lisB = getSimilar(backTNodes, "B", 0)
    lisC = getSimilar(backTNodes, "C", 0)
    lisD = getSimilar(backTNodes, "D", 0)
    lisE = getSimilar(backTNodes, "E", 0)
    lisF = getSimilar(backTNodes, "F", 0)

    lisAll = [lis0] ++ [lis1] ++ [lis2] ++ [lis3] ++ [lis4] ++ [lis5] ++
             [lis6] ++ [lis7] ++ [lis8] ++ [lis9] ++ [lisA] ++ [lisB] ++
             [lisC] ++ [lisD] ++ [lisE] ++ [lisF]

    level_neighbors = [Enum.at(routing_table, prefix)]

    nodes_neigh = if prefix == 3 do
                    list1 = Enum.at(routing_table, 0)
        			list2 = create_L2_list(lisAll, Enum.at(dyn_node,i), numbers)
                    list3 = create_L3_list(lisAll, Enum.at(dyn_node,i), numbers)
                    _list = [list1] ++ [list2] ++ [list3]
                else
                  if prefix == 2 do
                    list1 = Enum.at(routing_table, 0)
                    list2 = create_L2_list(lisAll, Enum.at(dyn_node,i), numbers)
                    _list = [list1] ++ [list2]
                  else
                    if prefix == 1 do
                      list1 = Enum.at(routing_table, 0)
                      _list = [list1]
                    else
                      []
                    end
                  end
                end

    level_neighbors = nodes_neigh ++ level_neighbors
    list_zero =[]
    level_neighbors = if prefix < 3 do
      list_zero = for _i <- prefix+1..3 do
                    list_zero ++ Enum.map(0..15, fn(_x)-> "0" end)
                  end
      level_neighbors ++ list_zero
    else
      level_neighbors
    end

    map = Map.put(map, Enum.at(dyn_node,i), level_neighbors)
   
    # For every node, update the current nodes routing table with the new node
    map_update = %{}
    map_update = for x<-0..length(keys_list)-1 do
                update_node = Enum.at(keys_list, x)
                routing_table = update_routing_table(Map.get(map, update_node), update_node, Enum.at(dyn_node,0))
                Map.put(map_update, update_node, routing_table)
              end
   
    map_update = Enum.reduce(map_update, fn(x, acc) -> Map.merge(x, acc, fn _k, v1, _v2 -> v1 end) end)

    _map = Map.merge(map, map_update)
  end

  
  def findRootNode(nodelist, node) do
  	# Return the root node of a node from nodelist
    digits = node |> String.split("", trim: true)

    list1 = findNode(nodelist, Enum.at(digits, 0), 0)
    _rootNode = if length(list1) == 1 do
                List.first(list1)
              else
                list2 = findNode(list1, Enum.at(digits, 1), 1)
                if length(list2) == 1 do
                  List.first(list2)
                else
                  list3 = findNode(list2, Enum.at(digits, 2), 2)
                  if length(list3) == 1 do
                    List.first(list3)
                  else
                    list4 = findNode(list3, Enum.at(digits, 3), 3)
                    List.first(list4)
                  end
                end
              end
  end
 
  def findNode(nodelist, digit, pos) do
  	# Returns a list of nodes IDs containing digit "digit" at position "pos"
    list = getSimilar(nodelist, digit, pos)
    _list = if list == [] do
        index = getIndex(digit)
        index = rem(index + 1, 16)
        digit = reverseIndex(index)
        findNode(nodelist, digit, pos)
        else
          list
        end
  end

  def reverseIndex(index) do
  	# Get the digit by index
    numbers = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
    _digit = Enum.at(numbers, index)
  end
 
  def getIndex(digit) do
  	# Get the index by digit
	numbers = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
	index = for x<-0..length(numbers)-1 do
	  _index = if digit == Enum.at(numbers, x) do
	      _index = x
	  end
	end
	index = Enum.filter(index, fn v -> v != nil end)
	List.first(index)
  end  

  def create_L1_list(lisAll, node) do
  	# Creates Level 1 neighbors list from a list of nodes for the given node
    _list_L1=[]
    _list_L1 = for x<-0..15 do
        list = Enum.at(lisAll, x)
        nearnode = getNearestNeighbor(list, node)
        _value = nearnode
    end
  end

 
  def create_L2_list(lisAll, node, numbers) do
	# Creates Level 2 neighbors list from a list of nodes for the given node
	list=[]
	_list = for x<-0..length(numbers)-1 do
		list ++ getMatchingNode_L2(lisAll, node, Enum.at(numbers, x))
	end
  end

  def create_L3_list(lisAll, node, numbers) do
	# Creates Level 3 neighbors list from a list of nodes for the given node
	list=[]
	_list = for x<-0..length(numbers)-1 do
		list ++ getMatchingNode_L3(lisAll, node, Enum.at(numbers, x))
	end
  end

  def create_L4_list(lisAll, node, numbers) do
	# Creates Level 4 neighbors list from a list of nodes for the given node
	list=[]
	_list = for x<-0..length(numbers)-1 do
		list ++ getMatchingNode_L4(lisAll, node, Enum.at(numbers, x))
	end
  end

  def getMatchingNode_L2(lisAll, node, x) do
  	# Returns matching nodes for level 2 from a list of nodes
  	# having first digit common with the node
      node = if is_binary(node) do
              node
            else
              to_string(node)
            end
      digits = node |> String.split("", trim: true)
      digit1 = Enum.at(digits, 0)
      digit2 = x

      index = getIndex(digit1)
      lis = Enum.at(lisAll, index)

      val=[]
      val = for y<-0..length(lis)-1 do
            l = Enum.at(lis, y)
            l = if is_binary(l) do
              l
            else
              to_string(l)
            end
          digs = l |> String.split("", trim: true)
          dig1 = Enum.at(digs, 0)
          dig2 = Enum.at(digs, 1)
          _val = if dig1 == digit1 and dig2 == digit2 do
              _val = val ++ Enum.at(lis, y)
          end
      end
      val = Enum.filter(val, fn v -> v != nil end)
      _value = Enum.at(val, 0)

      nearnode = getNearestNeighbor(val, node)
      value = nearnode

      _val = if value != nil do
              value
            else
              "0"
            end
  end

  def getMatchingNode_L3(lisAll, node, x) do
  	# Gets matching nodes for level 3 from a list of nodes
  	# having first and second digits common with the node
      node = if is_binary(node) do
        node
      else
        to_string(node)
      end

      digits = node |> String.split("", trim: true)

      digit1 = Enum.at(digits, 0)
      digit2 = Enum.at(digits, 1)
      digit3 = x

      index = getIndex(digit1)
      lis = Enum.at(lisAll, index)

      val=[]
      val = for y<-0..length(lis)-1 do

          l = Enum.at(lis, y)
          l = if is_binary(l) do
            l
          else
            to_string(l)
          end

          digs = l |> String.split("", trim: true)
          dig1 = Enum.at(digs, 0)
          dig2 = Enum.at(digs, 1)
          dig3 = Enum.at(digs, 2)
          _val = if dig1 == digit1 and dig2 == digit2 and dig3 == digit3 do
              _val = val ++ Enum.at(lis, y)
          end
      end
      val = Enum.filter(val, fn v -> v != nil end)
      _value = Enum.at(val, 0)

      nearnode = getNearestNeighbor(val, node)
      value = nearnode

      _val = if value != nil do
                value
            else
                "0"
      end
  end

  def getNearestNeighbor(lis, node) do
  	# Returns nearest neighbor for a node from a list of nodes
      len = length(lis)
      first_element = List.first(lis)

      lis = case {len, first_element, node} do
        {0, _, _} ->
          lis

        {1, x, y} when x == y ->
          lis

        {1, x, y} when x != y ->
          Enum.sort(lis ++ [node])

        _->
          Enum.sort(lis ++ [node])
      end

      len1 = length(lis)

      pos = []
      pos = for x<-0..len1-1 do
        m = Enum.at(lis, x)
        _pos = if  m == node do
          pos ++ x
        end
      end

      pos = Enum.filter(pos, fn p -> p != nil end)
      pos = List.first(pos)

      newNode =
      case {len1, pos} do
      {x, y} when x == 0 and y == nil->
        "0"

      {x, y} when x == 1 and y == 0->
        Enum.at(lis, 0)

      {x, y} when x == 2 and y == 0->
        Enum.at(lis, 1)

      {x, y} when x == 2 and y == 1->
        Enum.at(lis, 0)

      {x, y} when x > 2 and y == 0 ->
        Enum.at(lis, 1)

      {x, y} when x > 2 and y == x-1 ->
        Enum.at(lis, y-1)

      {x, y} when x > 2 and y > 0 ->
        val_left = Enum.at(lis, y-1)
        val_right = Enum.at(lis, y+1)
        val = Enum.at(lis, y)

        un = val|> to_charlist() |> List.to_integer(16)
        node = val_left|> to_charlist() |> List.to_integer(16)
        v = val_right|> to_charlist() |> List.to_integer(16)

        _value = case {un,node,v} do
          {x,y,z} when abs(x-y) > abs(x-z) ->
            val_right
          _ -> val_left
          end

      _ ->
        nil
      end
    newNode
  end

  def getMatchingNode_L4(lisAll, node, x) do
  	# Gets matching nodes for level 4 from a list of nodes
  	# with first, second and third digits common with the node
      digits = node |> String.split("", trim: true)
      digit1 = Enum.at(digits, 0)
      digit2 = Enum.at(digits, 1)
      digit3 = Enum.at(digits, 2)
      digit4 = x

      index = getIndex(digit1)
      lis = Enum.at(lisAll, index)

      val=[]
      val = for y<-0..length(lis)-1 do

          digs = Enum.at(lis, y) |> String.split("", trim: true)
          dig1 = Enum.at(digs, 0)
          dig2 = Enum.at(digs, 1)
          dig3 = Enum.at(digs, 2)
          dig4 = Enum.at(digs, 3)
          _val = if dig1 == digit1 and dig2 == digit2 and dig3 == digit3 and dig4 == digit4 do
              _val = val ++ Enum.at(lis, y)
          end
      end
      val = Enum.filter(val, fn v -> v != nil end)
      value = Enum.at(val, 0)
      _val = if value != nil do
                value
            else
                "0"
      end
  end

  def generate_nodes(numNodes,map_set) do
  	# Returns a map containing unique node IDs using SHA-1
     if(MapSet.size(map_set) < numNodes) do
        code = random_num_gen(4)
        sha_node  = :crypto.hash(:sha256, code) |> Base.encode16
        trun_node =  String.slice(sha_node, 0..3)
        map_set = MapSet.put(map_set,trun_node)
        generate_nodes(numNodes,map_set)
     else
         map_set
     end
  end

  def random_num_gen(length) do
  	 # Generates random Hexa decimal numbers of the given length
     len = if length > 1 do
              (1..length)
          else
              [1]
          end
     numbers = "0123456789ABCDEF"
     lists = numbers |> String.split("", trim: true)
     len |> Enum.reduce([], fn(_, acc) -> [Enum.random(lists) | acc] end)
     |> Enum.join("")
  end

  def getSimilar(nodelist, digit, position) do
  	# Returns a list of nodes having specified digit in the mentioned position
      lis=[]
      lis = for x<-0..length(nodelist)-1 do
          node = Enum.at(nodelist, x)
          _lis = if node != nil do
            split = node |> String.split("", trim: true)
            _lis = if Enum.at(split, position) == digit do
                lis ++ [Enum.at(nodelist, x)]
          else
            []
          end
          end
      end
      lis = List.flatten(Enum.filter(lis, fn x -> x != nil end))
      _lis = Enum.sort(lis)
  end

end

# Parsing CLI arguments
numNodes = Enum.at(System.argv(),0)
numRequests = Enum.at(System.argv(),1)
nodesFailed = Enum.at(System.argv(),2)

# Handle 2 input paramenters scenario
nodesFailed = if nodesFailed do
                nodesFailed
              else
                "0"
              end

n1 = String.to_integer(numNodes,10)
n2 = String.to_integer(numRequests,10)
n3 = String.to_integer(nodesFailed,10)

# Run Tapestry implementation only when total number of nodes are more than nodes failed
if n1 > n3 do

map = TapestrySimulator.Implementation.tapestry(n1, n2)
map1 = TapestrySimulator.Implementation.generateBackpointer(map)

# Add node dynamically
final_map = TapestrySimulator.Implementation.addNodeDynamically(map, map1)
final_map1 = TapestrySimulator.Implementation.generateBackpointer(final_map)

# Store back pointers
Storebkptr.start_link(final_map1)

# Start supervisor by passing node, routing table map during initialization
{:ok, pid} = Tapestry.Sup.start_link(final_map)

# Take children pids from supervisor
c = Supervisor.which_children(pid)
c = Enum.sort(c)

len = length(c)-1
map = %{}
map = Enum.map(0..len, fn i ->
head = Enum.at(c,i)
h_list = Tuple.to_list(head)
key = Enum.at(h_list,0)
val = Enum.at(h_list,1)
Map.put(map,key,val)
end)

map = Enum.reduce(map,fn(x,acc) -> Map.merge(x,acc,fn _k,v1,v2 -> [v1,v2] end) end)
keys_list = Map.keys(map)

# Store node IDs and respective PIDs in Storepid state for future reference
if n3>0 do
  node = Enum.take_random(keys_list, n3)
  nodePid = %{}
  nodePid = for i <- 0..length(node)-1 do
              _nodePid = Map.put(nodePid, Enum.at(node,i), "kill")
            end
  nodePid = Enum.reduce(nodePid,fn(x,acc) -> Map.merge(x,acc,fn _k,v1,_v2 -> v1 end) end)
  map1 = Map.merge(map,nodePid)
  Storepid.start_link(map1)
else
  Storepid.start_link(map)
end

# Exit only when all the <numNodes> number of peers performed <numRequests> number of requests 
parent = self()
convergence_factor = if n3 == 0 do
                      n2*n1
                    else
                      (n1-n3)*n2
                    end
quit = [parent]++[convergence_factor]

# Send the above created list to Dispstore so that it knows when to quit
Task.start_link(fn ->
    Dispstore.start_link(quit)
end)

for i <- 0..n1-1 do
    pid = Storepid.get_pid(Enum.at(keys_list,i))
    # Failed nodes cannot be source Nodes and send message
    if pid != "kill" do
      Nodes.send_msg(pid,0)
    end
end

time_wait = (convergence_factor) * 1000

# Quit storing when we reach required convergence, otherwise wait till default time
receive do
:work_is_done -> :ok
after
# Optional timeout
time_wait -> :timeout
end

# Converged nodes are stored in Dispstore state
list = Dispstore.print()
last_element = List.last(list)
list  = list  -- [last_element]
last_but_one_element = List.last(list)
list  = list  -- [last_but_one_element]

list = Enum.map(list, fn x ->
        if is_binary(x) do
            String.to_integer(x)
        else
            x
        end
        end)


max_hops = if length(list) > 0 do Enum.max(list) else 0 end
IO.puts("Maximum number of hops traversed to deliver message #{max_hops}")

else
	IO.puts("Wrong input arguments")
end