// given a list of bids, it returns all the bids under the maximum specified step 
bids_by_step([],MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 
bids_by_step([bid(Distance,MaxLoad,Role,Agent)|Bids],MaximumStep,Temp,Result)
:-
	Distance <= MaximumStep &
	bids_by_step(Bids,MaximumStep,[bid(MaxLoad,Role,Agent)|Temp],Result)
	.
bids_by_step(Bids,MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 
	
// given a list of bids, it indicates if the task can be accomplished
task_can_be_accomplished(Item,Qtd,[],TemQtd,Temp,Result) :- false.
task_can_be_accomplished(Item,Qtd,[bid(Step,Storage,Agent)|Bids],TempQtd,Temp,Result)
:- 
	default::available_items(Storage,Items)&
	.member(item(Item,QtdS),Items) &
//	(TempQtd+QtdS >= Qtd & Result=[storageItem(QtdS,Storage,Agent)|Temp]
	(QtdS >= Qtd & Result=[storageItem(QtdS,Storage,Agent)|Temp]
		|
	 task_can_be_accomplished(Item,Qtd,Bids,TempQtd+QtdS,[storageItem(QtdS,Storage,Agent)|Temp],Result)
	)
	.

// given a list of items, sums up the volume of all items
total_volume([],Total) :- Total = 0. 
total_volume([item(Item,Qty)|Items],Total+(Qty*Vol)) 
:-
	default::item(Item,Vol,_,_) &
	total_volume(Items,Total) 
	.
	
task_can_be_accomplished(TotalVolume,RequiredRoles,[],TemQtd,TempRoles,MaxStep) :- false.
task_can_be_accomplished(TotalVolume,RequiredRoles,[bid(Distance,MaxLoad,Role,Agent)|Bids],TempVol,TempRoles,Distance) 
:- 
	TempVol+MaxLoad >= TotalVolume &
	.difference(RequiredRoles,[Role|TempRoles],[])
	.
task_can_be_accomplished(TotalVolume,RequiredRoles,[bid(Distance,MaxLoad,Role,Agent)|Bids],TempVol,TempRoles,MaxStep) 
:- 
	task_can_be_accomplished(TotalVolume,RequiredRoles,Bids,TempVol+MaxLoad,[Role|TempRoles],MaxStep) 
	.

available_resources([],Vol,Roles)
:-
	Vol = 0 &
	Roles = []
	.
available_resources([bid(_,MaxLoad,Role,_)|Bids],Vol+MaxLoad,TRoles)
:-
	available_resources(Bids,Vol,Roles) &
	.union([Role],Roles,TRoles) 
	.

volume_task([],PVol,Volume) :- Volume = PVol.
volume_task([Item|Parts],PVol,Volume+IVol)
:-
	default::item(Item,IVol,_,_) &		
	volume_task(Parts,PVol,Volume)
	.
total_qty_item([],Qty,Volume) :- Volume = 0.
total_qty_item(TVol,CVol,MaxQty,VolTask,Qty)
:-
	TempQty = math.floor((TVol-CVol)/VolTask) &
	TempQty > 0 &
	Qty = math.min(TempQty,MaxQty)
	.
	
+!evaluate_bids(JobId,Tasks,Bids)
	: .sort(Bids,SortedBids) & available_resources(SortedBids,TLoad,TRoles)
<-	
	.print("Preparing evaluation ",SortedBids," ",TLoad," ",TRoles);
	!evaluate_task(Tasks,TLoad,TRoles,0,0,SortedBids);
	.	

+!evaluate_task([],TLoad,TRoles,TempLoad,MaxStep,Bids)
	: bids_by_step(Bids,MaxStep,[],Result)
<-
//	.print("Selected bids ",Result);
	+::selected_bids(Result);
	.
+!evaluate_task([item(Item,MaxQty)|Tasks],TLoad,TRoles,TempLoad,MaxStep,Bids)
	: 	default::item(Item,IVol,roles(IRoles),parts(IParts)) & 
		.difference(IRoles,TRoles,[]) & 
		volume_task(IParts,IVol,PVolume) &
		total_qty_item(TLoad,TempLoad,MaxQty,PVolume,PQty) & 
		task_can_be_accomplished(TempLoad+(PQty*PVolume),IRoles,Bids,0,[],NewMax)
<-	
	.print("Task ",Item," ",PQty," is feasible in ",NewMax," steps");	
	!selected_task(IParts,Item,PQty);
	!selected_task_assemble(IRoles,Item,PQty);
//	!evaluate_task(Tasks,TLoad,TRoles,TempLoad+(PQty*PVolume),NewMax,Bids);
	!evaluate_task([],TLoad,TRoles,TempLoad+(PQty*PVolume),NewMax,Bids); // I just want one task for evaluation, we need to fix coordination at moise
	.
+!evaluate_task([item(Item,Qty)|Tasks],TLoad,TRoles,TempLoad,MaxStep,Bids)
<-
	.print("Task ",Item," ",Qty," is unfeasible");	
	!evaluate_task(Tasks,TLoad,TRoles,TempLoad,MaxStep,Bids);
	.
+!selected_task_assemble([],Compound,PQty).
+!selected_task_assemble([Role|Roles],Compound,PQty)
<-	
	+::constraint_role(Role,Compound);
	!selected_task_assemble(Roles,Compound,PQty)
	.	
+!selected_task([],Compound,Qty).
+!selected_task([PItem|Parts],Compound,Qty)	
	: not ::selected_task(PItem,Compound,_,_) & default::item(PItem,Vol,_,_)
<-
	+::selected_task(PItem,Compound,Qty,entire);
	!selected_task(Parts,Compound,Qty);
	.
+!selected_task([PItem|Parts],Compound,Qty)	
	: ::selected_task(PItem,Compound,OldQty,Type) & default::item(PItem,Vol,_,_)
<-
	-::selected_task(PItem,Compound,_,_);
	+::selected_task(PItem,Compound,Qty+OldQty,Type);
	!selected_task(Parts,Compound,Qty);
	.

// ### AWARD ###	
+!award_agents(TaskId,DeliveryPoint,Winners)
	: ::selected_bids(Bids) & .sort(Bids,SortedBids) & .reverse(SortedBids,RBids)
<-
	.print("Sorted bids ",RBids," to ",DeliveryPoint);
	
//	for(::selected_task(TPItem,TCompound,TQty,_)){
//		.print("selected task ",TPItem," ",TCompound," ",TQty);
//	}
	
	for(.member(bid(Load,Role,Name),RBids)){
		+::awarded_agent(Name,Role,Load,[],[]);
	}
	!award_task(DeliveryPoint,RBids);
	
	for(::awarded_agent(Name,Role,Load,Duty,Tasks)){
		for(.member(assemble(Item,Qty),Duty)){
			manufactureItem(Item, Qty);
		}
		for(.member(retrieve(Storage,Item,Qty),Tasks)){
//			.print("retrieve ",Storage," ",Item," ",Qty);
			removeAvailableItem(Storage,Item,Qty,Result);
		}
	}		
	.findall(winner(Name,assembly,Duty,Tasks,TaskId),::awarded_agent(Name,Role,Load,Duty,Tasks) & not (Duty == [] & Tasks == []),Winners);
		
	.abolish(::selected_bids(_));
	.abolish(::awarded_agent(_,_,_,_,_));
	.abolish(::constraint_role(_,_));
	.abolish(::selected_task(_,_,_,_));
	.
	
assembler(Compound,Qty,Name)
:-
	default::item(Compound,Vol,_,_) &
	::constraint_role(Role,Compound) &
	::awarded_agent(Name,Role,Load,_,_) &
	Load >= Qty*Vol
	.	
assembler(Compound,Qty,Name)
:-
	default::item(Compound,Vol,_,_) &
	::awarded_agent(Name,_,Load,_,_) &
	Load >= Qty*Vol
	.
	
+!award_task(DeliveryPoint,Bids)
	: ::selected_task(Item,Compound,Qty,_)  & assembler(Compound,Qty,Assembler)
<-
	.print(Assembler," was selected as assembler of ",Compound);
	!award_assembler(Compound,Qty,Assembler);
	!award_retrieve(DeliveryPoint,Compound,Assembler,Assembler);
	!award_retrieves(DeliveryPoint,Compound,Assembler,Bids);
//	while(::selected_task(Item,Compound,Qty) & Qty > 1){
	while(::selected_task(MItem,Compound,MQty,MType) & MQty > 1){
		Qty1 = MQty div 2;
		Qty2 = (MQty div 2) + (MQty mod 2);
		.print("%%%%%%%%%%%%%%%%%%%%%% Failed allocation of ",MItem," ",Compound," ",MQty," spliting item in ",Qty1," ",Qty2);
		-::selected_task(MItem,Compound,MQty,MType);
		+::selected_task(MItem,Compound,Qty1,half_1);
		+::selected_task(MItem,Compound,Qty2,half_2);
		!award_retrieves(DeliveryPoint,Compound,Assembler,Bids);
	}	
	if (::selected_task(IfItem,Compound,IfQty,_)){
		.print(IfItem," ",IfQty," of ",Compound," was not allocated, revogating this allocation process");
		.abolish(::selected_task(_,_,_,_));
		.abolish(::awarded_agent(_,_,_,_,_));
	}
	!award_task(DeliveryPoint,Bids);
	.
+!award_task(DeliveryPoint,Bids).
	
+!award_retrieves(DeliveryPoint,Compound,Assembler,[]).
+!award_retrieves(DeliveryPoint,Compound,Assembler,Bids)
	: ::constraint_role(Role,Compound) & ::awarded_agent(Agent,Role,_,_,_)
<-
	.print(Compound," has constraint ",Role);
	!award_assist(Agent,Compound,Assembler);
	!award_retrieve(DeliveryPoint,Compound,Assembler,Agent);
	!award_retrieves(DeliveryPoint,Compound,Assembler,Bids);
	.
+!award_retrieves(DeliveryPoint,Compound,Assembler,[bid(_,_,Agent)|Bids])
<-
	!award_retrieve(DeliveryPoint,Compound,Assembler,Agent);
	!award_retrieves(DeliveryPoint,Compound,Assembler,Bids);
	.

+!award_retrieve(DeliveryPoint,Compound,Assembler,Agent)
	: ::selected_task(Item,Compound,Qty,Type) & ::awarded_agent(Agent,Role,Load,Duty,AssignedTasks) & default::item(Item,Vol,_,_) & (Qty*Vol) <= Load
<-
	.print("awarded ",Agent," ",AssignedTasks," to retrieve ",Item," in ",Qty," for ",Compound);
	-::awarded_agent(Agent,_,_,_,_);
	+::awarded_agent(Agent,Role,Load-(Qty*Vol),Duty,[retrieve(DeliveryPoint,Item,Qty)|AssignedTasks]);
	-::selected_task(Item,Compound,Qty,Type);
	!award_assist(Agent,Compound,Assembler);
	!award_retrieve(DeliveryPoint,Compound,Assembler,Agent);
	.
+!award_retrieve(DeliveryPoint,Compound,Assembler,Agent).

+!award_assist(Agent,Compound,Assembler)
	: ::awarded_agent(Agent,Role,Load,Duty,AssignedTasks) & not .member(assist(Assembler,Compound),Duty) & Agent \== Assembler
<-
	.print("awarded assist ",Agent," to ",Assembler);
	-::awarded_agent(Agent,_,_,_,_);
	.union([assist(Assembler,Compound)],Duty,NewDuty);
	+::awarded_agent(Agent,Role,Load,NewDuty,AssignedTasks);
	-::constraint_role(Role,Compound);
	.
+!award_assist(Agent,Compound,Assembler).
+!award_assembler(Compound,Qty,Agent)
	: ::awarded_agent(Agent,Role,Load,Duty,AssignedTasks)
<-
	.print("awarded assembler ",Agent," ",Compound," ",Qty);
	-::awarded_agent(Agent,_,_,_,_);
	.union([assemble(Compound,Qty)],Duty,NewDuty);
	+::awarded_agent(Agent,Role,Load,NewDuty,AssignedTasks);
	-::constraint_role(Role,Compound);	
	.
