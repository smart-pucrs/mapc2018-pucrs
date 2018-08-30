volume_task([],PVol,Volume) :- Volume = PVol.
volume_task([required(Item,Qty)|Tasks],PVol,Volume+(IVol*Qty))
:-
	default::item(Item,IVol,_,_) &		
	volume_task(Tasks,PVol,Volume)
	.
	
task_can_be_accomplished(TotalVolume,[],TemQtd,MaxStep) :- false.
task_can_be_accomplished(TotalVolume,[bid(Distance,MaxLoad,Agent)|Bids],TempVol,Distance) 
:- 
	TempVol+MaxLoad >= TotalVolume
	.
task_can_be_accomplished(TotalVolume,[bid(Distance,MaxLoad,Agent)|Bids],TempVol,MaxStep) 
:- 
	task_can_be_accomplished(TotalVolume,Bids,TempVol+MaxLoad,MaxStep) 
	.

// given a list of bids, it returns all the bids under the maximum specified step 
bids_by_step([],MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 
bids_by_step([bid(Distance,MaxLoad,Agent)|Bids],MaximumStep,Temp,Result)
:-
	Distance <= MaximumStep &
	bids_by_step(Bids,MaximumStep,[bid(MaxLoad,Agent)|Temp],Result)
	.
bids_by_step(Bids,MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 

+!announce(Tasks,Deadline,JobId,Agents,CNPBoardName)
<- 
	generateTaskId(TaskId);
	.concat("cnp_delivery_",TaskId,CNPBoardName);
	.print("Creating task ",CNPBoardName," for task ",Tasks);
	makeArtifact(CNPBoardName, "cnp.ContractNetBoard", [Tasks, Deadline, .length(Agents)]);
	.send(Agents,tell,delivery::task(Tasks,CNPBoardName,TaskId));	
	.
	
+!evaluate_bids(Tasks,Bids)
	: .sort(Bids,SortedBids) &.print("a ",Tasks)& volume_task(Tasks,20,TLoad) &task_can_be_accomplished(TLoad,SortedBids,0,MaxStep) & bids_by_step(SortedBids,MaxStep,[],SelectedBids)
<-	
//	.print("Required load ",TLoad,"can be transported in ",MaxStep);
//	.print("Selected bids for delivery ",SelectedBids);
	for(.member(required(Item,Qty),Tasks)){
		+::selected_task(Item,Qty,entire);
	}
	+::selected_bids(SelectedBids);
	.	
+!evaluate_bids(Tasks,Bids)
<-	
	.print("Insufficient load to delivery load");
	.
	
	
+!award_agents(TaskId,DeliveryPoint,Winners)
	: ::selected_bids(Bids) & .sort(Bids,SortedBids) & .reverse(SortedBids,RBids)
<-
	.print("Sorted bids ",RBids," to ",DeliveryPoint);
	
	for(.member(bid(Load,Name),RBids)){
		+::awarded_agent(Name,Load,[]);
	}
	
	!award_deliveries(DeliveryPoint,Bids);	
	while(::selected_task(MItem,MQty,MType)){
		Qty1 = MQty div 2;
		Qty2 = (MQty div 2) + (MQty mod 2);
		.print("%%%%%%%%%%%%%%%%%%%%%% Failed allocation of ",MItem," ",MQty," spliting item in ",Qty1," ",Qty2);
		-::selected_task(MItem,MQty,MType);
		+::selected_task(MItem,Qty1,half_1);
		+::selected_task(MItem,Qty2,half_2);
		!award_deliveries(DeliveryPoint,Bids);
	}
	
	for(::awarded_agent(Name,_,Tasks) & Tasks \== []){
		for(.member(delivery(Storage,Item,Qty),Tasks)){
			removeAvailableItem(Storage,Item,Qty,Result);
		}
		.send(Name,tell,default::winner(TaskId,Tasks,DeliveryPoint));
	}		
	.findall(winner(Name,Tasks,TaskId),::awarded_agent(Name,Load,Tasks) & Tasks \== [],Winners);
//	.send(Ag,tell,strategies::winner(JobId,Deliveries,DeliveryPoint));
		
	.abolish(::selected_bids(_));
	.abolish(::awarded_agent(_,_,_));
	.abolish(::selected_task(_,_,_));
	.
+!award_agents(TaskId,DeliveryPoint,[]).
	
+!award_deliveries(DeliveryPoint,[]).
+!award_deliveries(DeliveryPoint,[bid(_,Agent)|Bids])
<-
	!award_delivery(DeliveryPoint,Agent);
	!award_deliveries(DeliveryPoint,Bids);
	.
+!award_delivery(DeliveryPoint,Agent)
	: ::selected_task(Item,Qty,Type) & ::awarded_agent(Agent,Load,AssignedTasks) & default::item(Item,Vol,_,_) & (Qty*Vol) <= Load
<-
//	.print("awarded ",Agent," ",AssignedTasks," to delivery ",Item," in ",Qty);
	-::awarded_agent(Agent,_,_);
	+::awarded_agent(Agent,Load-(Qty*Vol),[delivery(DeliveryPoint,Item,Qty)|AssignedTasks]);
	-::selected_task(Item,Qty,Type);
	!award_delivery(DeliveryPoint,Agent);
	.
+!award_delivery(DeliveryPoint,Agent).
	
+!enclose(CNPBoardName)
<- 		
	remove[artifact_name(CNPBoardName)];
	.print("Artefact ",CNPBoardName," removed");
	.