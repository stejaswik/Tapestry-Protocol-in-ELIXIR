# Tapestry Algorithm in ELIXIR

1. Implement network join and routing using Tapestry Protocol. <br />

2. To run the code: to\path\dir>mix run project3.exs <numNodes> <numRequests> <br />

3. BONUS - For failure model: to\path\dir>mix run project3.exs <numNodes> <numRequests> <numFailureNodes> <br />

4. Tapestry algorithm works for given number of nodes, number of requests, and number of nodes failed. <br />
   We get the maximum hop count as the output. <br />

   We have implemented the following as a part of this project : <br />
   (i) Generating unique 4-digit node IDs using SHA-1 <br />
   (ii) Populate and Optimize routing tables for nodes in the network <br />
   (iii) Dynamic node insertion using a root node <br />
   (iv) Updating routing tables as part of node join  <br />
   (v) Computing maximum hops required for message passing from a source node to a destination node  <br />
   (vi) Failure Model implementation for handling involuntary node deletion <br />
 
5. Largest network we managed to deal with : <br />
   numNodes = 5000, numRequests = 2 <br />

6. Largest network we managed to deal with for failure model : <br />
   numNodes = 5000, numRequests = 2, numFailureNodes = 500 <br />

7. Maximum hop count achieved = 4 <br />

8. Minimum hop count = 0 <br />








