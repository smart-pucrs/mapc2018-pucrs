// given a list of compound items, return a list o required roles to build those items
get_required_roles([],Temp,RequiredRoles) 
:- 	Temp = RequiredRoles.
get_required_roles([Item | Items],Temp,RequiredRoles) 
:- 	default::item(Item,_,roles(Roles),parts(Compound)) & 
	.union(Roles,Temp,AllRoles) &
	get_required_roles(Compound,AllRoles,RequiredRoles).
	
// figures out the roles of the available agents
get_available_roles(Temp,AvailableRoles) 
:- AvailableRoles = [drone,motorcycle,car,truck].

// given a list of storages, return the itemized available items; return pattern item(Item,Qtd)
get_available_items([],Temp,ListItems)
:- 
	ListItems = Temp.
get_available_items([Storage|Storages],Temp,ListItems)
:-
	default::available_items(Storage,Items) & 
	.concat(Items,Temp,NewList)&
	get_available_items(Storages,NewList,ListItems) 
	.
// given a list of items, sums up all items of the same type
sum_up_items([],Temp,ListItems)
:-
	ListItems = Temp
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	.member(item(Item,OldQtd),Temp) & 
	.difference(Temp,[item(Item,OldQtd)],NewList) &
	sum_up_items(Items,[item(Item,Qtd+OldQtd)|NewList],ListItems)
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	not .member(item(Item,_),Temp) & 
	sum_up_items(Items,[item(Item,Qtd)|Temp],ListItems)
	.
// given a list of required items and quantities "required(Item,Qtd)", and another list of available items and quantities "item(Item,Qtd)", evaluates the difference taking into account the quantities
difference_in_quantities([],_):-true.
difference_in_quantities([required(Item,ReqQtd)|RequiredItems],AvailableItems)
:-
	.member(item(Item,AvaQtd),AvailableItems) &
	AvaQtd >= ReqQtd &
	difference_in_quantities(RequiredItems,AvailableItems)
	.

evaluate_agents(Items)
:- 
	get_required_roles(Items,[],RequiredRoles) & 
	get_available_roles([],AvailableRoles)  & 
	.difference(RequiredRoles,AvailableRoles,[]).
evaluate_items(Items,StoragesToLook)
:- 	
	get_available_items(StoragesToLook,[],ItemizedAvailableItems)&
	sum_up_items(ItemizedAvailableItems,[],AvailableItems)&
	difference_in_quantities(Items,AvailableItems)
	.
evaluate_steps
:-
	true
	.

+!job_estimate(Id,Items)
	: rules::get_items_names(Items,NamesItems)
<-
	?evaluate_agents(NamesItems); 
	?evaluate_items(Items,[storage1,storage2]);
	?evaluate_steps;
	.print(Id," is feasible");
	.
-!job_estimate(Id,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	.

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
					if ( Role == car ) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,car,Item,assist); -+free_cars(ListCNew); }
					else { if ( Role == drone ) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,drone,Item,assist); -+free_drones(ListDNew); }
					else { if ( Role == motorcycle ) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,moto,Item,assist); -+free_motos(ListMNew); }
					else { if ( Role == truck ) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,truck,Item,assist); -+free_trucks(ListTNew); }
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
					if (FC >= FD & FC >= FM & FC >= FT) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,car,Item,assist); -+free_cars(ListCNew); }
					else { if (FD >= FC & FD >= FM & FD >= FT) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,drone,Item,assist); -+free_drones(ListDNew); }
					else { if (FM >= FD & FM >= FC & FM >= FT) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,moto,Item,assist); -+free_motos(ListMNew); }
					else { if (FT >= FD & FT >= FM & FT >= FC) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,truck,Item,assist); -+free_trucks(ListTNew); }
					}}}
				}
			}
			-+role_check(0);
		}
	}
	
	if ( awarded(Ag,truck,It,Mo) ) { -awarded(Ag,truck,It,Mo); +awarded(Ag,truck,It,assemble) }
	else { if ( awarded(Ag,car,It,Mo) ) { -awarded(Ag,car,It,Mo); +awarded(Ag,car,It,assemble) }
	else { if ( awarded(Ag,moto,It,Mo) ) { -awarded(Ag,moto,It,Mo); +awarded(Ag,moto,It,assemble) }
	else { if ( awarded(Ag,drone,It,Mo) ) { -awarded(Ag,drone,It,Mo); +awarded(Ag,drone,It,assemble) }
	}}}
	
	+countP(-1);
	for ( awarded(Agent,_,I,Mode) ) {
		?default::item(I,_,_,parts(P));
		.length(P,NParts);
		?countP(CP);
		if ( CP+1 >= NParts ) { -+countP(-1); }
		?countP(CPNew);
		-+countP(CPNew+1);
		.nth(CPNew+1,P,Part);
		.print(Agent," was awarded with obtaining the part ",Part," and assembling item ",I);
		.send(Agent,tell,winner(Part,I,Mode));
		-awarded(Agent,_,I,Mode);
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
	