{ include("behaviour/job/estimate.asl", estimates) }

verify_bases([],NodesList,Result) :- Result = "true".
verify_bases([Item|Parts],NodesList,Result) :- .member(node(_,_,_,Item),NodesList) & verify_bases(Parts,NodesList,Result).
verify_bases([Item|Parts],NodesList,Result) :- not .member(node(_,_,_,Item),NodesList) & Result = "false".

@priced_job[atomic]
+default::job(Id,Storage,Reward,Start,End,Items)
	: true
<-
 	.print("Received ",Id,", starting the priced job process.");
	!accomplished_priced_job(Id,Storage,Items);
	.

@resourceList[atomic]
+default::resNode(NodeId,Lat,Lon,Item)
	: resourceList(List) & not .member(NodeId,List)
<- 
	.print("New resource node: ",NodeId," for item: ",Item);
	-+resourceList([node(NodeId,Lat,Lon,Item)|List]);
	.
	
+!set_workshop_storage
	: default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::storageList(SList) & new::workshopList(WList) & rules::closest_facility(SList, CLat, CLon, Storage) & rules::closest_facility(WList, Storage, Workshop)
<-
	+centerStorage(Storage);
	+centerWorkshop(Workshop);
	.print("Closest storage from the center is ",Storage);
	.print("Closest workshop from the center is ",Workshop);
	.

+!accomplished_priced_job(Id,Storage,Items)
<-
	!estimates::priced_estimate(Id,Items);
	.
-!accomplished_priced_job(Id,Storage,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	.

@create_initial_tasks[atomic]
+!create_initial_tasks
	: resourceList(NodesList) & centerStorage(Storage) & centerWorkshop(Workshop)
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
		if ( FreeTotal >= 4 ) {
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
				for ( .member(Part,Parts) ) { ?default::item(Part,Vol,_,_); +part(Part,Vol); }
			}
			-+role_check(0);
		}
	}
	
	if ( awarded(Ag,truck,It,Mo) ) { -awarded(Ag,truck,It,Mo); +awarded(Ag,truck,It,assemble); +assembler(Ag); }
	else { if ( awarded(Ag,car,It,Mo) ) { -awarded(Ag,car,It,Mo); +awarded(Ag,car,It,assemble); +assembler(Ag); }
	else { if ( awarded(Ag,moto,It,Mo) ) { -awarded(Ag,moto,It,Mo); +awarded(Ag,moto,It,assemble); +assembler(Ag); }
	else { if ( awarded(Ag,drone,It,Mo) ) { -awarded(Ag,drone,It,Mo); +awarded(Ag,drone,It,assemble); +assembler(Ag); }
	}}}
	
	?default::joined(org,OrgId);
	?taskId(TaskId);
	.term2string(TaskId,TaskIdS);
	org::createScheme(TaskIdS, st, SchArtId)[wid(OrgId)];
	-+taskId(TaskId+1);
	
	if ( awarded(_,drone,_,_) ) { ?load_drone(LDrone); +max_load(LDrone); }
	else { if ( awarded(_,moto,_,_) ) { ?load_drone(LMoto); +max_load(LMoto); }
	else { if ( awarded(_,car,_,_) ) { ?load_drone(LCar); +max_load(LCar); }
	else { if ( awarded(_,truck,_,_) ) { ?load_drone(LTruck); +max_load(LTruck); }
	}}}
	.findall(N,initiator::part(_,N),L);
	.max(L,MaxVol);
	?max_load(MaxLoad);
	.count(initiator::part(_,_),NPart);
	+number_of_items((MaxLoad div MaxVol));
	+number_of_assemble((4 * (MaxLoad div MaxVol)) div NPart);
	?number_of_items(NItems);
	?number_of_assemble(NAssemble);
	.abolish(initiator::part(_,_));
	-max_load(_);
	?assembler(Assembler);
	
	+countP(-1);
	for ( awarded(Agent,Role,I,Mode) ) {
		?default::item(I,_,_,parts(P));
		.length(P,NParts);
		?countP(CP);
		if ( CP+1 >= NParts ) { -+countP(-1); }
		?countP(CPNew);
		-+countP(CPNew+1);
		.nth(CPNew+1,P,Part);
		.print(Agent," was awarded with obtaining ",NItems,"# of ",Part," and assembling item ",I);
		.send(Agent,tell,bidder::winner(Part,NItems,NAssemble,I,Mode,Assembler,Storage,Workshop,TaskIdS));
		-awarded(Agent,Role,I,Mode);
	}
	-countP(_);
	-number_of_items(_);
	-number_of_assemble(_);
	-assembler(_);
	
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
	if ( FreeTotal >= 4 & FCar > 0 & FDrone > 0 & FMoto > 0 & FTruck > 0 ) { !create_initial_tasks; }
	else { 
		.print("Not enough free agents.");
		if (FCar > 0) { for ( .member(AgentFree,ListCar) ) { .send(AgentFree,achieve,strategies::free); } }
		if (FDrone > 0) { for ( .member(AgentFree,ListDrone) ) { .send(AgentFree,achieve,strategies::free); } }
		if (FMoto > 0) { for ( .member(AgentFree,ListMoto) ) { .send(AgentFree,achieve,strategies::free); } }
		if (FTruck > 0) { for ( .member(AgentFree,ListTruck) ) { .send(AgentFree,achieve,strategies::free); } }
	}
	.
	