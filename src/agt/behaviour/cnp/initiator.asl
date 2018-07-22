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

+!create_initial_tasks
	: resourceList(NodesList)
<-
	+taskList([]);
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
		?free_cars(ListCar);
		?free_drones(ListDrone);
		?free_motos(ListMoto);
		?free_trucks(ListTruck);
		.length(ListCar,FCar);
		.length(ListDrone,FDrone);
		.length(ListMoto,FMoto);
		.length(ListTruck,FTruck);
		FreeTotal = FCar + FDrone + FMoto + FTruck;
		if ( FreeTotal >= 5 ) {
			?default::item(Item,_,roles(Roles),parts(Parts));
			for ( .member(Role,Roles) ) {
				if ( (Role == car & not .empty(ListCar)) | (Role == drone & not .empty(ListDrone)) | (Role == motorcycle & not .empty(ListMoto)) | (Role == truck & not .empty(ListTruck)) ) { 
					?role_check(N); 
					-+role_check(N+1);
				}
			}
			?role_check(N);
			if (.length(Roles,N)) {
				.print("We can assemble the following item: ",Item," which requires these roles: ",Roles," and these bases: ",Parts);
				for ( .member(Role,Roles) ) {
					if ( Role == car ) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,Item); -+free_cars(ListCNew); }
					else { if ( Role == drone ) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,Item); -+free_drones(ListDNew); }
					else { if ( Role == motorcycle ) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,Item); -+free_motos(ListMNew); }
					else { if ( Role == truck ) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,Item); -+free_trucks(ListTNew); }
					}}}
				}
				for ( .range(I,1,4-N) ) {
					?free_cars(ListC);
					?free_drones(ListD);
					?free_motos(ListM);
					?free_trucks(ListT);
					.length(ListC,FC);
					.length(ListD,FD);
					.length(ListM,FM);
					.length(ListT,FT);
					if (FC >= FD & FC >= FM & FC >= FT) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,Item); -+free_cars(ListCNew); }
					else { if (FD >= FC & FD >= FM & FD >= FT) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,Item); -+free_drones(ListDNew); }
					else { if (FM >= FD & FM >= FC & FM >= FT) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,Item); -+free_motos(ListMNew); }
					else { if (FT >= FD & FT >= FM & FT >= FC) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,Item); -+free_trucks(ListTNew); }
					}}}
				}
			}
			-+role_check(0);
		}
	}
	+countP(-1);
	for ( initiator::awarded(Agent,I) ) {
		?default::item(I,_,_,parts(P));
		.length(P,NParts);
		?countP(CP);
		if ( CP+1 >= NParts ) { -+countP(-1); }
		?countP(CPNew);
		-+countP(CPNew+1);
		.nth(CPNew+1,P,Part);
		.print(Agent," was awarded with obtaining the part ",Part," and assembling item ",I);
		.send(Agent,tell,winner(Part,I));
		-awarded(Agent,I);
	}
	-countP(_);
	?free_cars(ListCar);
	?free_drones(ListDrone);
	?free_motos(ListMoto);
	?free_trucks(ListTruck);
	.length(ListCar,FCar);
	.length(ListDrone,FDrone);
	.length(ListMoto,FMoto);
	.length(ListTruck,FTruck);
	FreeTotal = FCar + FDrone + FMoto + FTruck;
	-taskList(_);
	if ( FreeTotal >= 5 & FCar > 0 & FDrone > 0 & FMoto > 0 & FTruck > 0 ) { !create_initial_tasks; }
	else { .print("Not enough free agents."); }
	.
	