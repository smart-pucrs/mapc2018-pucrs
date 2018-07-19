resourceList([]).

verify_bases([],NodesList,Result) :- Result = "true".
verify_bases([Item|Parts],NodesList,Result) :- .member(node(_,_,_,Item),NodesList) & verify_bases(Parts,NodesList,Result).
verify_bases([Item|Parts],NodesList,Result) :- not .member(node(_,_,_,Item),NodesList) & Result = "false".

@resourceList[atomic]
+default::resNode(NodeId,Lat,Lon,Item)
	: resourceList(List) & not .member(NodeId,List)
<- 
	.print("New resource node: ",NodeId," for item: ",Item);
	.term2string(ItemT,Item);
	-+resourceList([node(NodeId,Lat,Lon,ItemT)|List]);
	.

+!initiator::create_initial_tasks
	: resourceList(NodesList)
<-
	.findall(item(Item,Parts),default::item(Item,_,_,parts(Parts)) & Parts \== [], AssembledList);
	for ( .member(item(Item,Parts),AssembledList) ) {
		?verify_bases(Parts,NodesList,Result);
		.print(Item," assemble ready result is ",Result);
	}
	.
	