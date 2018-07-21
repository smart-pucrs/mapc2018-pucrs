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
		?free_cars(TypeC,ListCar);
		?free_drones(TypeD,ListDrone);
		?free_motos(TypeM,ListMoto);
		?free_trucks(TypeT,ListTruck);
		.length(ListCar,FCar);
		.length(ListDrone,FDrone);
		.length(ListMoto,FMoto);
		.length(ListTruck,FTruck);
		FreeTotal = FCar + FDrone + FMoto + FTruck;
		if ( FreeTotal >= 5 ) {
			?default::item(Item,_,roles(Roles),parts(Parts));
			for ( .member(Role,Roles) ) {
				if ( (Role == TypeC & not .empty(ListCar)) | (Role == TypeD & not .empty(ListDrone)) | (Role == TypeM & not .empty(ListMoto)) | (Role == TypeT & not .empty(ListTruck)) ) { 
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
				for ( .range(I,1,5-N) ) {
					?free_cars(_,ListC);
					?free_drones(_,ListD);
					?free_motos(_,ListM);
					?free_trucks(_,ListT);
					.length(ListC,FC);
					.length(ListD,FD);
					.length(ListM,FM);
					.length(ListT,FT);
					if (FC >= FD & FC >= FM & FC >= FT) { ?free_cars(_,[Vehicle|ListCNew]); +awarded(Vehicle,Item); -+free_cars(car,ListCNew); }
					else { if (FD >= FC & FD >= FM & FD >= FT) { ?free_drones(_,[Vehicle|ListDNew]); +awarded(Vehicle,Item); -+free_drones(drone,ListDNew); }
					else { if (FM >= FD & FM >= FC & FM >= FT) { ?free_motos(_,[Vehicle|ListMNew]); +awarded(Vehicle,Item); -+free_motos(motorcycle,ListMNew); }
					else { if (FT >= FD & FT >= FM & FT >= FC) { ?free_trucks(_,[Vehicle|ListTNew]); +awarded(Vehicle,Item); -+free_trucks(truck,ListTNew); }
					
					}}}
				}
			}
			-+role_check(0);
		}
	}
	
	for ( awarded(V,I) ) {
		.print(V," was awarded with obtaining the assembled item ",I);
		-awarded(V,I);
	}
	
	?free_cars(_,ListCar);
	?free_drones(_,ListDrone);
	?free_motos(_,ListMoto);
	?free_trucks(_,ListTruck);
	.length(ListCar,FCar);
	.length(ListDrone,FDrone);
	.length(ListMoto,FMoto);
	.length(ListTruck,FTruck);
	FreeTotal = FCar + FDrone + FMoto + FTruck;
	-taskList(_);
	if ( FreeTotal >= 5 & FCar > 0 & FDrone > 0 & FMoto > 0 & FTruck > 0 ) { !create_initial_tasks; }
	else { .print("Not enough free agents."); }
	.
	