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
		if (Result == "true") {
			?taskList(TaskList);
			-+taskList([Item|TaskList]);
		}
	}
	?taskList(TaskL);
	for ( .member(Item,TaskL) ) {
		?default::item(Item,_,roles(Roles),parts(Parts));
		?free_cars(TypeC,ListC);
		?free_drones(TypeD,ListD);
		?free_motos(TypeM,ListM);
		?free_trucks(TypeT,ListT);
		for ( .member(Role,Roles) ) {
			if ( (Role == TypeC & not .empty(ListC)) | (Role == TypeD & not .empty(ListD)) | (Role == TypeM & not .empty(ListM)) | (Role == TypeT & not .empty(ListT)) ) { 
				?role_check(N); 
				-+role_check(N+1);
			}
		}
		?role_check(N);
		if (.length(Roles,N)) {
			.print("We can assemble the following item: ",Item," which requires these roles: ",Roles," and these bases: ",Parts);
			for ( .member(Role,Roles) ) {
				if ( Role == TypeC ) { ?free_cars(TypeC,[Vehicle|ListCNew]); +awarded(Vehicle,Item); -+free_cars(TypeC,ListCNew); }
				if ( Role == TypeD ) { ?free_drones(TypeD,[Vehicle|ListDNew]); +awarded(Vehicle,Item); -+free_drones(TypeD,ListDNew); }
				if ( Role == TypeM ) { ?free_motos(TypeM,[Vehicle|ListMNew]); +awarded(Vehicle,Item); -+free_motos(TypeM,ListMNew); }
				if ( Role == TypeT ) { ?free_trucks(TypeT,[Vehicle|ListTNew]); +awarded(Vehicle,Item); -+free_trucks(TypeT,ListTNew); }	
			}
			
		}
		-+role_check(0);
	}
	
	for ( awarded(V,I) ) {
		.print(V," was awarded with obtaining the assembled item ",I);
	}
	.
	