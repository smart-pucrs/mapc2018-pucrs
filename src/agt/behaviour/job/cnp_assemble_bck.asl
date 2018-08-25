task_id(0).

// given a list of bids, it returns all the bids under the maximum specified step 
bids_by_step([],MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 
bids_by_step([bid(Distance,MaxLoad,Role,Agent)|Bids],MaximumStep,Temp,Result)
:-
	Step <= MaximumStep &
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
	
task_can_be_accomplished(TotalVolume,RequiredRoles,[],TemQtd,TempRoles) :- false.
task_can_be_accomplished(TotalVolume,RequiredRoles,[bid(Distance,MaxLoad,Role)|Bids],TempVol,TempRoles) 
:- 
	TempVol+MaxLoad >= TotalVolume &
	.difference(RequiredRoles,[Role|TempRoles],[])
	.
task_can_be_accomplished(TotalVolume,[bid(Distance,MaxLoad,Role)|Bids],TempVol,TempRoles) 
:- 
	task_can_be_accomplished(TotalVolume,Bids,TempVol+MaxLoad,[Role|TempRoles]) 
	.

step_finish_task_role([],Bids,TempStep,Step) :- Step = TempStep.
step_finish_task_role([Role|Roles],Bids,TempStep,Step)
:-
	.member(bid(Distance,_,Role,_),Bids) &
	Distance >= TempStep &
	step_finish_task_role(Roles,Bids,Distance,Step)
	.
	
constraint_role(Item)
:-
	default::item(Item,_,role(Roles),_) & 
	::partial_roles(WorkerAgents) & 
	.difference(Roles,WorkerAgents,[])
	.	
constraint_load(Item)
:-
	::required_load(RLoad) & 
	::partial_load(Load) & 
	Load >= RLoad
	.	

total_available([],0,[]).
total_available([bid(_,MaxLoad,Role,_)|Bids],Vol+MaxLoad,TRoles)
:-
	total_available(Tasks,Vol,Roles) &
	.union([Role],Roles,TRoles) 
	.

total_constraints([],0,[]).
total_constraints([item(Item,Qty)|Tasks],Vol+(Qty*IVol),TRoles)
:-
	default::item(Item,IVol,_,role(IRoles)) &
	total_constraints(Tasks,Vol,Roles) &
	.union(IRoles,Roles,TRoles) 
	.
	
+!evaluate_bids(JobId,Tasks,Bids)
<-	
	.sort(Bids,SortedBids);	
	for(.member(bid(Distance,MaxLoad,Role,Agent),Bids)){
		+::bid(Distance,MaxLoad,Role,Agent);
	}
	.	

+!evaluate_task([],TempLoad,MaxStep,Bids)
	: bids_by_step(Bids,MaxStep,[],Result)
<-
	+::selected_bids(Result);
	.
+!evaluate_task([item(Item,Qty)|Tasks],TempLoad,MaxStep,Bids)
	: default::item(Item,IVol,parts(IParts),role(IRoles)) & .member(bid(Distance,MaxLoad,Role,Agent) & Distance<=MaxStep & MaxLoad<=IVol*Qty,ListBids) 
<-	
	.print("Task ",Item," ",Qty," is feasible");	
	!selected_task(IParts,Item,Qty);
	!selected_task(IRoles,Item);
	!evaluate_task(Tasks,TempLoad+(IVol*Qty),Bids);
	.
+!selected_task([],Compound).
+!selected_task([Role|Roles],Compound)
<-
	+::selected_task(Role,Compound);
	.	
+!selected_task([],Compound,Qty).
+!selected_task([PItem|Parts],Compound,Qty)	
	: not ::selected_task(PItem,Compound,_) & default::item(PItem,Vol,_,_)
<-
	+::selected_task(PItem,Compound,Qty);
	!selected_task(Parts,Compound,Qty);
	.
+!selected_task([PItem|Parts],Compound,Qty)	
	: ::selected_task(PItem,Compound,OldQty) & default::item(PItem,Vol,_,_)
<-
	-::selected_task(PItem,Compound,_);
	+::selected_task(PItem,Compound,Qty+OldQty);
	!selected_task(Parts,Compound,Qty);
	.
	
	
+!evaluate_task([item(Item,Qty)|Tasks],TempLoad,Bids)
	: total_available(Bids,TQty,TRoles) & default::item(Item,IVol,_,role(IRoles)) & TempLoad+(IVol*Qty) <= TQty & .difference(IRoles,TRoles,[])
<-	
	+::feasible_task(item(Item,Qty));
	!evaluate_task(Tasks,TempLoad+(IVol*Qty),Bids);
	.
+!evaluate_task([item(Item,Qty)|Tasks],TempLoad,Bids)
	: total_available(Bids,TQty,TRoles) & default::item(Item,IVol,_,role(IRoles)) & TempLoad+(IVol*Qty) <= TQty & .difference(IRoles,TRoles,[])
<-	
	+::feasible_task(item(Item,Qty));
	!evaluate_task(Tasks,TempLoad+(IVol*Qty),Bids);
	.
+!evaluate_task([item(Item,Qty)|Tasks],TempLoad,Bids)
	: default::item(Item,_,_,role(Roles)) & step_finish_task_role(Roles,Bids,0,Step)
<-		
	.findall(bid(Distance,MaxLoad,Role,Agent),::bid(Distance,MaxLoad,Role,Agent) & Distance<=Step,ListBids);

	for(.member(bid(Distance,MaxLoad,Role,Agent),ListBids)){
		+::bid(Distance,MaxLoad,Role,Agent);
	}
	.
	
+!evaluate_bids(JobId,Tasks,Bids)
<-	
	.sort(Bids,SortedBids);	
	for(.member(bid(Distance,MaxLoad,Role,Agent),Bids)){
		+::bid(Distance,MaxLoad,Role,Agent);
	}
	

	
	
	.print("sorted bids");
	-+::required_load(0);
	-+::partial_load(0);
	-+::partial_roles([]);
	-+::partial_bids([]);
	-+::partial_tasks([]);
	.print("created initial beliefs");
	!evaluate_bids(Tasks,SortedBids);	
	.abolish(::required_load(_));
	.abolish(::partial_load(_));
	.abolish(::partial_roles(_));
	.
+!evaluate_bids(JobId,Tasks,Bids)
<-	
	.sort(Bids,SortedBids);
	.print("sorted bids");
	-+::required_load(0);
	-+::partial_load(0);
	-+::partial_roles([]);
	-+::partial_bids([]);
	-+::partial_tasks([]);
	.print("created initial beliefs");
	!evaluate_bids(Tasks,SortedBids);	
	.abolish(::required_load(_));
	.abolish(::partial_load(_));
	.abolish(::partial_roles(_));
	.

+!evaluate_bids([],Bids).
+!evaluate_bids([item(Item,Qty)|Tasks],Bids)
	: default::item(Item,Vol,_,_) & ::required_load(RLoad) & ::partial_tasks(PTasks)
<-	
	-+::required_load(RLoad+(Qty*Vol));
	!check_constraint(SortedBids,constraint_role(Item));
	!check_constraint(SortedBids,constraint_load(Item));
	-+::partial_tasks([item(Item,Qty)|PTasks]);
	!evaluate_bids(Tasks,Bids);
	.
-!evaluate_bids([item(Item,Qty)|Tasks],Bids)
<-	
	!evaluate_bids(Tasks,Bids);
	.


+!check_constraint([],Constraint)
<-
	.fail;
	.
+!check_constraint(Bids,Constraint)
	: Constraint & ::partial_roles(PartialWorkers) & ::partial_load(PartialLoad) & ::partial_bids(SelectedBids)
<-
	-+::partial_roles([Role|PartialWorkers]);
	-+::partial_load(PartialLoad);
	-+::partial_bids([bid(MaxLoad,Agent)|SelectedBids]);
	-+::partial_distance(Distance);
	.
+!check_constraint([bid(Distance,MaxLoad,Role,Agent)|Bids],Constraint)
	: ::partial_roles(PartialWorkers) & ::partial_load(PartialLoad) & ::partial_bids(SelectedBids)
<-	
	-+::partial_roles([Role|PartialWorkers]);
	-+::partial_load(PartialLoad);
	-+::partial_bids([bid(MaxLoad,Agent)|SelectedBids]);
	-+::partial_distance(Distance);
	!check_constraint(Bids,Constraint);
	.


+!check_constraint([],Constraint)
<-
	.fail;
	.
+!check_constraint([bid(Distance,MaxLoad,Role,Agent)|Bids])
	: default::item(Item,_,role(Roles),_) & 
	::partial_roles(WorkerAgents) & 
	.difference(Roles,WorkerAgents,[]) &
	::required_load(RLoad) & 
	::partial_load(Load) & 
	Load >= RLoad 
<-
	-+::partial_roles([Role|PartialWorkers]);
	-+::partial_load(PartialLoad);
	-+::partial_bids([bid(MaxLoad,Agent)|SelectedBids]);
	-+::partial_distance(Distance);
	.
+!check_constraint([bid(Distance,MaxLoad,Role,Agent)|Bids],Constraint)
	: ::partial_roles(PartialWorkers) & ::partial_load(PartialLoad) & ::partial_bids(SelectedBids)
<-	
	-+::partial_roles([Role|PartialWorkers]);
	-+::partial_load(PartialLoad);
	-+::partial_bids([bid(MaxLoad,Agent)|SelectedBids]);
	-+::partial_distance(Distance);
	!check_constraint(Bids,Constraint);
	.
	
+!award_agents(Id,DeliveryPoint)
	: ::partial_bids(Bids) & .sort(Bids,SortedBids) & .reverse(SortedBids,RBids)
<-
	-+::partial_bids(RBids);
	
	.abolish(::partial_bids(_));
	.abolish(::partial_tasks(_));
	.

+!award_task(DeliveryPoint,Item,Qty,Vol,[bid(MaxLoad,Agent)|Bids])
	: ::partial_bids(Bids) & ::awarded_agent(Agent,AssignedTasks)
<-
	-::awarded_agent(Agent,_);	
	if((MaxLoad/Vol) >= Qty){
		QtyCarry = Qty;
	}else{
		QtyCarry = MaxLoad/Vol;
	}
	
	+::awarded_agent(Agent,[item(Item,Qty-QtyCarry)|AssignedTasks]);
	!award_task(DeliveryPoint,Item,Qty-QtyCarry,Vol,Bids);
	.
+!award_task(DeliveryPoint,[item(Item,Qty)|Task])
	: ::partial_tasks([item(Item,Qty)|Tasks]) & ::partial_bids([bid(MaxLoad)|Bids]) & default::item(Item,Vol,_,_) 
<-
	for(.member(item(Item,Qty),Tasks)){
		?::partial_bids(Bids);
		for(.member(bid(MaxLoad,Agent),Bids)){
			QtyCarry = MaxLoad/Vol;
			?::awarded_agent(Agent,AssignedTasks);
			-::awarded_agent(Agent,_);
			+::awarded_agent(Agent,[item(Item,QtyCarry)|AssignedTasks]);
		}
		
		if (QtyCarry >= Qty){
			
		}
	}
	.abolish(::partial_bids(_));
	.abolish(::partial_tasks(_));
	.	
+!award_agents(DeliveryPoint,[item(Item,Qty)|Task])
	: ::partial_bids(Bids) & .nth(0,SortedBids) & ::partial_tasks(Tasks)
<-
	.abolish(::partial_bids(_));
	.abolish(::partial_tasks(_));
	.
	


// [delivery(Storage,[item(Item,Qtd)])]
+!send_awards(JobId,DeliveryPoint)
	: .findall(Agent,::award(Agent,_,_),LAgents) & .union(LAgents,LAgents,Agents)
<-
	for(.member(Ag,Agents)){
		.findall(delivery(Storage,Items),::award(Ag,Storage,Items),Deliveries);
		.print("Sending award to ",Ag," of ",Deliveries);
		.send(Ag,tell,strategies::winner(JobId,Deliveries,DeliveryPoint));
		.abolish(::award(Ag,_,_));
	}	
	.	
+!award_agents(JobId,DeliveryPoint,Item,Qtd,[storageItem(QtdS,Storage,Agent)|Bids])
	: QtdS >= Qtd
<-
	if (award(Agent,Storage,Items)){
		-+award(Agent,Storage,[item(Item,Qtd)|Items]);		
	}else{
		+award(Agent,Storage,[item(Item,Qtd)]);
	}	
	default::removeAvailableItem(Storage,Item,Qtd,Result);
	!send_awards(JobId,DeliveryPoint);
	.
+!award_agents(JobId,DeliveryPoint,Item,Qtd,[storageItem(QtdS,Storage,Agent)|Bids])
<-
	if (award(Agent,Storage,Items)){
		-+award(Agent,Storage,[item(Item,QtdS)|Items]);
	}else{
		+award(Agent,Storage,[item(Item,QtdS)]);
	}
	!award_agents(JobId,DeliveryPoint,Item,Qtd-QtdS,Bids);
	.
	
+!enclose(CNPBoardName)
<- 		
	remove[artifact_name(CNPBoardName)];
	.print("Artefact ",CNPBoardName," removed");
	.