task_id(0).

// given a list of bids, it returns all the bids under the maximum specified step 
bids_by_step([],MaximumStep,Temp,Result) 
:-
	.sort(Temp,Result)
	. 
bids_by_step([bid(Step,Storage,Agent)|Bids],MaximumStep,Temp,Result)
:-
	Step <= MaximumStep &
	bids_by_step(Bids,MaximumStep,[bid(Step,Storage,Agent)|Temp],Result)
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

+!announce(Task,Deadline,JobId,Agents,CNPBoardName)
	: task_id(TaskId)
<- 
	-+task_id(TaskId+1);
	.concat("cnp_delivery_",TaskId,CNPBoardName);
	.print("Creating task ",CNPBoardName," for task ",Task);
	makeArtifact(CNPBoardName, "cnp.ContractNet", [Task, Deadline, .length(Agents)]);
	.send(Agents,tell,delivery::task(Task,CNPBoardName,TaskId));	
	.
	
//+!evaluate_bids(JobId,required(Item,Qtd),CNPBoardName,AwardedBids)
//<-
//	getBidsTask(Bids) [artifact_name(CNPBoardName)];
//	if (.length(Bids) \== 0) {		
//		.print("Bids received ",Bids);
//		.sort(Bids,SortedBids);
//		.print("Bids ",SortedBids);
//		.nth(0,SortedBids,bid(InitialStep,_,_));
//		?bids_by_step(SortedBids,InitialStep,[],UnderMaximumBids);
//		.print("minim ",UnderMaximumBids);
//		?task_can_be_accomplished(Item,Qtd,UnderMaximumBids,0,[],BestBids);
//		.sort(BestBids,SortedBestBids);
//		.print("B ",SortedBestBids);
//		.reverse(SortedBestBids,AwardedBids);
//		.print("R B ",AwardedBids);
//	}
//	else {
//		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
//		.fail(noBids);
//	}	
//	.
+!evaluate_bids(JobId,required(Item,Qtd),CNPBoardName,AwardedBids)
<-
	getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
		.sort(Bids,SortedBids);
		.nth(0,SortedBids,bid(InitialStep,_,_));
		!evaluate_bids(Item,Qtd,SortedBids,InitialStep,AwardedBids);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		.fail(noBids);
	}	
	.
+!evaluate_bids(Item,Qtd,SortedBids,InitialStep,AwardedBids)
<-	
	?bids_by_step(SortedBids,InitialStep,[],UnderMaximumBids);
	if (task_can_be_accomplished(Item,Qtd,UnderMaximumBids,0,[],BestBids)){
		.sort(BestBids,SortedBestBids);
		.reverse(SortedBestBids,AwardedBids);
	}else{
//		.print("Task cannot be accomplished, trying again");
		.difference(SortedBids,UnderMaximumBids,NewList);
		.nth(0,NewList,bid(Initial,_,_));
		!evaluate_bids(Item,Qtd,SortedBids,Initial,AwardedBids);
	}	
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