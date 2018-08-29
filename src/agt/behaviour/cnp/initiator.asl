{ include("behaviour/job/estimate.asl", estimates) }
{ include("behaviour/job/cnp_delivery.asl", cnpd) }
{ include("behaviour/job/cnp_assemble.asl", cnpa) }

verify_bases([],NodesList,Result) :- Result = "true".
verify_bases([Item|Parts],NodesList,Result) :- .member(node(_,_,_,Item),NodesList) & verify_bases(Parts,NodesList,Result).
verify_bases([Item|Parts],NodesList,Result) :- not .member(node(_,_,_,Item),NodesList) & Result = "false".


// ### LIST PRIORITY ###
get_final_qty_item(Item,Qty) :- final_qty_item(Item,Qty) | Qty=0.
+!compound_item_quantity([])
	: must_update
<-
	.print("Updating list of desired items in stock");
	.findall(item(Item,Qty),::compound_item_quantity(Item,Qty),ListItems);
	!update_item_quantity(ListItems);
	for(::final_qty_item(NewItem,NewQty)){
		if (default::item(NewItem,_,_,parts([]))){
			setDesiredBase(NewItem,NewQty);
		} else{
			setDesiredCompound(NewItem,NewQty);
		}
	}	
	.abolish(::final_qty_item(_,_));
	-must_update;
	.print("Stock updated");
	.
+!compound_item_quantity([]).
+!compound_item_quantity([required(Item,Qty)|Items])
<-
	!compound_item_quantity(Item,Qty);
	!compound_item_quantity(Items);
	.
+!compound_item_quantity(Item,Qty)
	: compound_item_quantity(Item,CurrentQty) & CurrentQty>=Qty
	.
+!compound_item_quantity(Item,Qty)
<-
	-compound_item_quantity(Item,_);	
	+compound_item_quantity(Item,Qty);	
	+must_update;
	.
+!update_item_quantity([]).
+!update_item_quantity([item(Item,Qty)|List])
	: ::get_final_qty_item(Item,CurrentQty) & default::item(Item,_,_,parts(Parts))
<-
	!update_item_quantity(List);
	
	-::final_qty_item(Item,_);
	+::final_qty_item(Item,CurrentQty+Qty);
	for(.member(PartItem,Parts)){
		?::get_final_qty_item(PartItem,OldQty);
		-::final_qty_item(PartItem,_);
		+::final_qty_item(PartItem,(OldQty+CurrentQty+Qty));
	}
	.
	
// ### ASSEMBLE COMPOUND ITEMS ###
//@checkAssemble[atomic]
+!criar_grupo
<-
	.print("Testando o grupo");
	?default::joined(org,OrgId);
//	?default::focused(_,org,OId);
	lookupArtifact(org,OId)[wid(OrgId)];
	org::createGroup(oteste, manufactory, GroupId)[artifact_id(OId),wid(OrgId)];
	org::createScheme(steste, assembly, SchArtId)[wid(OrgId)];
	org::focus(GroupId)[wid(OrgId)];	
//	org::debug("teste")[artifact_name(oteste)];
	org::adoptRole(assembler)[artifact_name(oteste)];
	org::addScheme(steste)[artifact_name(oteste)];
	.print("grupo criado");
//	org::destroy[artifact_name(oteste)];
//	.abolish(org::focused(_,oteste,_)); // why do I have to use abolish?
	.print("destrui local");	
	org::removeScheme(steste)[wid(OrgId)];
	org::destroyGroup(oteste)[artifact_id(OId),wid(OrgId)];
	.print("FIm do teste");
	.
+default::baseStored
	: not ::must_check_compound  & strategies::centerStorage(Storage)
<-
	+::must_check_compound;
	.print("Chamou o Based Stored");
	+action::reasoning_about_belief(Storage);
	.wait({+default::actionID(_)});
	
//	!!criar_grupo;
	
//	addAvailableItem(storage0,item0,10); // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item1,10);
//	addAvailableItem(storage0,item2,10);
//	addAvailableItem(storage0,item3,10);
//	addAvailableItem(storage0,item4,10);
	
	!estimates::compound_estimate(Items);
	if (Items \== []) { 
		.print("@@@@@@@@@@@@@@@@@@@@@ We have items to assemble ",Items); 
		.term2string(Items,ItemsS);
		
		!allocate_tasks(cnpa,none,assemble(Items),[gatherer,explorer_drone],Storage);		
	}
	else { 
		.print("££££££££££ Can't assemble anything yet."); 
//		-::must_check_compound;
	}
	-action::reasoning_about_belief(Storage);
	-::must_check_compound;
 	.

// ### PRICED JOBS ###
@priced_job[atomic]
+default::job(Id,Storage,Reward,Start,End,Items)
	: default::step(S) //& S >= 11
<-
	+action::reasoning_about_belief(Id);
 	.print("Received ",Id,", Items ",Items," starting the priced job process.");
 	!compound_item_quantity(Items);
	!!accomplished_priced_job(Id,Storage,Items);
//	-action::reasoning_about_belief(Id);
	.
+!accomplished_priced_job(Id,Storage,Items)
	: not entroo
<-
	+entroo;
	!estimates::priced_estimate(Id,Items);
	.print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ ",Id," is feasible! ");
    !allocate_delivery_tasks(Id,Items,Storage);
    -action::reasoning_about_belief(Id);
    .
-!accomplished_priced_job(Id,Storage,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	-action::reasoning_about_belief(Id);
    .
 
//+!allocate_delivery_tasks(Id,[],DeliveryPoint).
//+!allocate_delivery_tasks(Id,[required(Item,Qtd)|Items],DeliveryPoint)
//	: .findall(Agent,default::play(Agent,Role,_) & (Role==gatherer|Role==explorer),ListAgents)
//<-     
//	!cnpd::announce(delivery_task(DeliveryPoint,Item,Qtd),10000,Id,ListAgents,CNPBoardName);
//       
//    !cnpd::evaluate_bids(Id,required(Item,Qtd),CNPBoardName,AwardedBids);
//       
//    !cnpd::award_agents(Id,DeliveryPoint,Item,Qtd,AwardedBids);
//       
//    !cnpd::enclose(CNPBoardName);
//
//    !allocate_delivery_tasks(Id,Items,DeliveryPoint);
//    .
    
+!allocate_tasks(Module,Id,Task,Roles,DeliveryPoint)
	: .findall(Agent,default::play(Agent,Role,_) & .member(Role,Roles),ListAgents)
<-     
//	announce(Task,10000,ListAgents,CNPBoardName);
//	announce(Task,10000,[vehicle1,vehicle3,vehicle5,vehicle14,vehicle28],CNPBoardName);
	announce(Task,10000,ListAgents,CNPBoardName);
//	!Module::announce(Task,10000,Id,ListAgents,CNPBoardName);
       
    getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
		!Module::evaluate_bids(Id,Task,Bids);
       
	    !Module::award_agents(CNPBoardName,DeliveryPoint,Winners);
	    .print("### Winners: ",Winners);
	    award(Winners);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		.fail(noBids);
	} 
	clear(CNPBoardName);  
    .

+!accomplished_priced_job(Id,Storage,Items)
<-
	!estimates::priced_estimate(Id,Items);
	.
-!accomplished_priced_job(Id,Storage,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	.

//@create_item_tasks[atomic]
//+!create_item_tasks
//	: resourceList(NodesList) & centerStorage(Storage) & centerWorkshop(Workshop)
//<-
//	if (not bidder::winner(_,_,_,_,_,_,_,_,_)) { !action::forget_old_action(Id); +action::committedToAction(Id); }
//	!strategies::not_free;
//	+taskList([]);
//	.findall(item(Item,Parts),default::item(Item,_,_,parts(Parts)) & Parts \== [], AssembledList);
//	for ( .member(item(Item,Parts),AssembledList) ) {
//		?verify_bases(Parts,NodesList,Result);
//		if (Result == "true") {
//			?taskList(TaskList);
//			-+taskList([Item|TaskList]);
//		}
//	}
//	?taskList(TaskL);
//	for ( .member(Item,TaskL) ) {
//		?free_cars(ListCar);
//		?free_drones(ListDrone);
//		?free_motos(ListMoto);
//		?free_trucks(ListTruck);
//		.length(ListCar,FCar);
//		.length(ListDrone,FDrone);
//		.length(ListMoto,FMoto);
//		.length(ListTruck,FTruck);
//		FreeTotal = FCar + FDrone + FMoto + FTruck;
//		?default::item(Item,_,roles(Roles),parts(Parts));
//		.length(Parts,NumberParts);
//		if (NumberParts == 2) { NumberAgents = 4; }
//		else { if (NumberParts == 3) { NumberAgents = 6; }
//		else { NumberAgents = NumberParts } }
//		if ( FreeTotal >= NumberAgents ) {
//			for ( .member(Role,Roles) ) {
//				if ( (Role == car & not .empty(ListCar)) | (Role == drone & not .empty(ListDrone)) | (Role == motorcycle & not .empty(ListMoto)) | (Role == truck & not .empty(ListTruck)) ) { 
//					?role_check(N); 
//					-+role_check(N+1);
//				}
//			}
//			?role_check(N);
//			if (.length(Roles,N)) {
//				.print("We can assemble the following item: ",Item," which requires these roles: ",Roles," and these bases: ",Parts);
//				for ( .member(Role,Roles) ) {
//					if ( Role == car ) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,car,Item,assist); -+free_cars(ListCNew); }
//					else { if ( Role == drone ) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,drone,Item,assist); -+free_drones(ListDNew); }
//					else { if ( Role == motorcycle ) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,moto,Item,assist); -+free_motos(ListMNew); }
//					else { if ( Role == truck ) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,truck,Item,assist); -+free_trucks(ListTNew); }
//					}}}
//				}
//				for ( .range(I,1,NumberAgents-N) ) {
//					?free_cars(ListC);
//					?free_drones(ListD);
//					?free_motos(ListM);
//					?free_trucks(ListT);
//					.length(ListC,FC);
//					.length(ListD,FD);
//					.length(ListM,FM);
//					.length(ListT,FT);
//					if (FC >= FD & FC >= FM & FC >= FT) { ?free_cars([Vehicle|ListCNew]); +awarded(Vehicle,car,Item,assist); -+free_cars(ListCNew); }
//					else { if (FD >= FC & FD >= FM & FD >= FT) { ?free_drones([Vehicle|ListDNew]); +awarded(Vehicle,drone,Item,assist); -+free_drones(ListDNew); }
//					else { if (FM >= FD & FM >= FC & FM >= FT) { ?free_motos([Vehicle|ListMNew]); +awarded(Vehicle,moto,Item,assist); -+free_motos(ListMNew); }
//					else { if (FT >= FD & FT >= FM & FT >= FC) { ?free_trucks([Vehicle|ListTNew]); +awarded(Vehicle,truck,Item,assist); -+free_trucks(ListTNew); }
//					}}}
//				}
//				for ( .member(Part,Parts) ) { ?default::item(Part,Vol,_,_); +part(Part,Vol); }
//				
//				if ( awarded(Ag,truck,It,Mo) ) { -awarded(Ag,truck,It,Mo); +awarded(Ag,truck,It,assemble); +assembler(Ag); }
//				else { if ( awarded(Ag,car,It,Mo) ) { -awarded(Ag,car,It,Mo); +awarded(Ag,car,It,assemble); +assembler(Ag); }
//				else { if ( awarded(Ag,moto,It,Mo) ) { -awarded(Ag,moto,It,Mo); +awarded(Ag,moto,It,assemble); +assembler(Ag); }
//				else { if ( awarded(Ag,drone,It,Mo) ) { -awarded(Ag,drone,It,Mo); +awarded(Ag,drone,It,assemble); +assembler(Ag); }
//				}}}
//				
//				?default::joined(org,OrgId);
//				?taskId(TaskId);
//				.term2string(TaskId,TaskIdS);
//				org::createScheme(TaskIdS, st, SchArtId)[wid(OrgId)];
//				-+taskId(TaskId+1);
//				
//				if ( awarded(_,drone,_,_) ) { ?load_drone(LDrone); +max_load(LDrone); }
//				else { if ( awarded(_,moto,_,_) ) { ?load_drone(LMoto); +max_load(LMoto); }
//				else { if ( awarded(_,car,_,_) ) { ?load_drone(LCar); +max_load(LCar); }
//				else { if ( awarded(_,truck,_,_) ) { ?load_drone(LTruck); +max_load(LTruck); }
//				}}}
//				.findall(Volume,initiator::part(_,Volume),L);
//				.max(L,MaxVol);
//				?max_load(MaxLoad);
//				.count(initiator::part(_,_),NPart);
//				+number_of_items((MaxLoad div MaxVol));
//				+number_of_assemble((NumberAgents * (MaxLoad div MaxVol)) div NPart);
//				?number_of_items(NItems);
//				?number_of_assemble(NAssemble);
//				.abolish(initiator::part(_,_));
//				-max_load(_);
//				?assembler(Assembler);
//				
//				+countP(-1);
//				if (not awarded(vehicle1,_,_,_)) { +skip; }
//				for ( awarded(Agent,Role,I,Mode) ) {
//					?default::item(I,_,_,parts(P));
//					.length(P,NParts);
//					?countP(CP);
//					if ( CP+1 >= NParts ) { -+countP(-1); }
//					?countP(CPNew);
//					-+countP(CPNew+1);
//					.nth(CPNew+1,P,Part);
//					.print(Agent," was awarded with obtaining ",NItems,"# of ",Part," and assembling item ",I);
//					.send(Agent,tell,bidder::winner(Part,NItems,NAssemble,I,Mode,Assembler,Storage,Workshop,TaskIdS));
//					-awarded(Agent,Role,I,Mode);
//				}
//				-countP(_);
//				-number_of_items(_);
//				-number_of_assemble(_);
//				-assembler(_);
//				
//			}
//			-+role_check(0);
//		}
//	}
//	
//	?free_cars(ListCar);
//	?free_drones(ListDrone);
//	?free_motos(ListMoto);
//	?free_trucks(ListTruck);
//	.length(ListCar,FCar);
//	.length(ListDrone,FDrone);
//	.length(ListMoto,FMoto);
//	.length(ListTruck,FTruck);
//	FreeTotal = FCar + FDrone + FMoto + FTruck;
//	-taskList(_);
//	if ( FreeTotal >= 4 & FCar > 0 & FDrone > 0 & FMoto > 0 & FTruck > 0 ) { !create_item_tasks; }
//	else { .print("Not enough free agents."); if (skip) { -skip; !!strategies::free; } }
//	.
//	
////+!send_free
////	: free_cars(ListCar) & free_drones(ListDrone) & free_motos(ListMoto) & free_trucks(ListTruck)
////<-
////	for ( .member(AgentFree,ListCar) ) { .send(AgentFree,achieve,strategies::free); }
////	for ( .member(AgentFree,ListDrone) ) { .send(AgentFree,achieve,strategies::free); }
////	for ( .member(AgentFree,ListMoto) ) { .send(AgentFree,achieve,strategies::free); }
////	for ( .member(AgentFree,ListTruck) ) { .send(AgentFree,achieve,strategies::free); }
////	.
//	
//@addCarFree[atomic]
//+!add_agent_to_free(car)[source(Agent)]
//	: free_cars(FreeCars)
//<-
//	-+free_cars([Agent|FreeCars]);
//	!check_free;
//	.
//@addDroneFreeSelf[atomic]
//+!add_agent_to_free(drone)[source(self)]
//	: free_drones(FreeDrones) & .my_name(Me)
//<-
//	-+free_drones([Me|FreeDrones]);
//	!check_free;
//	.	
//@addDroneFree[atomic]
//+!add_agent_to_free(drone)[source(Agent)]
//	: free_drones(FreeDrones)
//<-
//	-+free_drones([Agent|FreeDrones]);
//	!check_free;
//	.
//@addMotoFree[atomic]
//+!add_agent_to_free(motorcycle)[source(Agent)]
//	: free_motos(FreeMotos)
//<-
//	-+free_motos([Agent|FreeMotos]);
//	!check_free;
//	.
//@addTruckFree[atomic]
//+!add_agent_to_free(truck)[source(Agent)]
//	: free_trucks(FreeTrucks)
//<-
//	-+free_trucks([Agent|FreeTrucks]);
//	!check_free;
//	.
//
//@checkFree[atomic]	
//+!check_free
//	: free_cars(FreeCars) & free_drones(FreeDrones) & free_motos(FreeMotos) & free_trucks(FreeTrucks)
//<-
//	.length(FreeCars,FCar);
//	.length(FreeDrones,FDrone);
//	.length(FreeMotos,FMoto);
//	.length(FreeTrucks,FTruck);
//	FreeTotal = FCar + FDrone + FMoto + FTruck;
//	if (FreeTotal >= 25) { !!create_item_tasks; }
//	.


	