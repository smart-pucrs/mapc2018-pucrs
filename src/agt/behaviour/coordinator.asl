resourceList([]).

init_coord("vehicle26",I,C,N,List,Result,ResultFinal) :- ResultFinal = Result.
init_coord(Vehicle,I,N,N,List,Result,ResultFinal) :- .concat("vehicle",I,VehicleNew) & .nth(N-1,List,NodeId) & init_coord(VehicleNew,I+1,1,N,List,[order(VehicleNew,NodeId)|Result],ResultFinal).
init_coord(Vehicle,I,C,N,List,Result,ResultFinal) :- C \== N & .concat("vehicle",I,VehicleNew) & .nth(C-1,List,NodeId) & init_coord(VehicleNew,I+1,C+1,N,List,[order(VehicleNew,NodeId)|Result],ResultFinal).


@resourceList[atomic]
+default::resNode(NodeId,Lat,Lon,Item)
	: resourceList(List) & not .member(NodeId,List)
<- 
	.print("New resource node: ",NodeId," for item: ",Item);
	-+resourceList([node(NodeId,Lat,Lon,Item)|List]);
	.

@initCoord[atomic]
+!initial_coordination
	: .count(default::resNode(_,_,_,_),N) & resourceList(List) & List \== []
<-
	.print("Number of res nodes ",N);
	?init_coord("",1,1,N,List,[],Result);
	for ( .member(order(Vehicle,node(NodeId,Lat,Lon,Item)),Result)) {
		.send(Vehicle,achieve,gather::go_gather(node(NodeId,Lat,Lon,Item)));
	}
	.
@initCoord2[atomic]
+!initial_coordination
<-
	.print("There are no initial resource nodes, sending agents to their nearest charging station.");
	for ( .range(I,1,26) ) {
		.concat("vehicle",I,VehicleNew);
		.send(VehicleNew,achieve,explore::go_explore_charging);
	}
	.