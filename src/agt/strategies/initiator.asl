{include("strategies/job/auction/evaluate-auction.asl",evaluation_auction)}

task_id(0).

//debug
//+default::buy_coordination(ShopId,List) <- .print(ShopId," : ",List).

+default::job(_, _, _, _, _, _) : not initiator::accept_jobs <- !update_free;.
@job[atomic]
+default::job(Id, Storage, Reward, Start, End, Items)
	: default::check_bases(Items,Result) & Result == "false" & initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<- 
	+action::hold_action(Id);
	.print("New job ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End);
	.print("Items required: ",Items);
	!evaluate_job(Items, End, Storage, Id, Reward);
	.
+default::job(Id, Storage, Reward, Start, End, Items) : default::check_bases(Items,Result) & Result == "true".
+default::job(Id, Storage, Reward, Start, End, Items) <- .print("Ignoring job ",Id); !update_free; .

+default::auction(_, _, _, _, _, _, _, _, _) : not initiator::accept_jobs <- !update_free;.
@oldAuction[atomic]
+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items)	
	: evaluation_auction::bidding(Id,_,_,_)
<-	
	!evaluation_auction::analyse_bid_posted(Id);
	.
@newAuction[atomic]
+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items)	
<-
//	.wait(default::step(Start));
	.print("New auction job ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End," has current bid of ",Bid," time for bids ",Time);
	.print("Items required: ",Items);
	!evaluation_auction::first_analysis(Id);
	.
+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items) <- .print("Ignoring auction job ",Id,", it shoud have not passed here").


+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items) : not initiator::accept_jobs <- +mission(Id, Storage, Items, End, Reward, Fine); .print("Ignoring mission ",Id," for now."); .
@mission[atomic]
+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items)
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<- 
//	+action::hold_action(Id);
	+mission(Id, Storage, Items, End, Reward, Fine);
	.print("New mission ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End," or pay ",Fine);
	.print("Items required: ",Items);
	!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
	.
+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items) <- +mission(Id, Storage, Items, End, Reward, Fine); .print("Ignoring mission ",Id," for now.").
	
+!decompose(Items,ListItems,ListToolsNew,Id)
<-
	?default::decomposeRequirements(Items,[],Bases);
	+bases([],Id);
	for ( .member(Item,Bases) ) {
		?bases(L,Id);
		.concat(L,Item,New);
		-bases(L,Id);
		+bases(New,Id);
	}
	?bases(B,Id);
	-bases(B,Id);
	if (.substring("tool",B)) {
		?default::separateItemTool(B,ListTools,ListItems); 
		?default::removeDuplicateTool(ListTools,ListToolsNew);
	}
	else { ListToolsNew = []; ListItems = B; }
	.

+!evaluate_job(Items, End, Storage, Id, Reward)
	: new::vehicle_job(Role,Speed) & new::workshopList(WList) & default::steps(TotalSteps) & default::step(Step) & initiator::free_agents(FreeAgents) & default::get_roles(FreeAgents,[],Roles) & default::get_tools(Roles,[],AvailableTools) & initiator::eval_shop_route(FarthestShop,RouteShop)
<-
	!decompose(Items,ListItems,ListToolsNew,Id);
	.length(ListToolsNew,NumberOfBuyTool);
	.length(ListItems,NumberOfBuyItem);
	.length(Items,NumberOfAssemble);
	?default::concat_bases(ListItems,[],ListItemsConcat);
	if ( default::check_tools(ListToolsNew,AvailableTools,ResultT) & ResultT == "true" & default::check_buy_list(ListItemsConcat,ResultB) & ResultB == "true" & default::check_multiple_buy(ListItemsConcat,AddSteps) & default::check_price(ListToolsNew,ListItems,0,ResultP) & .print("Estimated cost ",ResultP * 1.1," reward ",Reward) & ResultP * 1.1 < Reward & actions.closest(Role,WList,Storage,ClosestWorkshop) & actions.route(Role,Speed,FarthestShop,ClosestWorkshop,RouteWorkshop) & actions.route(Role,Speed,ClosestWorkshop,Storage,RouteStorage) & Estimate = RouteShop+RouteWorkshop+RouteStorage+NumberOfBuyTool+NumberOfBuyItem+NumberOfAssemble+AddSteps+25 & .print("Estimate ",Estimate+Step," < ",End) & Estimate + Step < End & Step + Estimate < TotalSteps ) {
		!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
	}
	else { 
		.print("Job ",Id," failed evaluation, ignoring it.");
		!update_eval;
		-action::hold_action(Id);
		!evaluation_auction::has_set_to_free;
	}
	.
	
+!evaluate_mission(Items, End, Storage, Id, Reward, Fine)
	: initiator::accept_jobs & not initiator::eval(Id) & default::steps(TotalSteps) & default::step(Step) & initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<-
	+eval(Id);
	.print("Evaluating mission ",Id," at step ",Step);
	if ( Step + 40 < TotalSteps & Step + 40 < End ) {
		+action::hold_action(Id);
		!decompose(Items,ListItems,ListToolsNew,Id);
		!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
	}
	else { 
		.print("Mission ",Id," failed evaluation, ignoring it.");
		-action::hold_action(Id);
		-mission(Id, Storage, Items, End, Reward, Fine);
		+failed_mission(Id, End, Fine);
		-eval(Id);
	}
.
+!evaluate_mission(Items, End, Storage, Id, Reward, Fine) <- .print("Mission is already being evaluated").

@sep_task[atomic]
+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items)
	: not cnp(_) & new::max_bid_time(Deadline) & initiator::free_trucks(FreeTrucks) & .length(FreeTrucks,NumberOfTrucks) & initiator::free_agents(FreeAgents) & .length(FreeAgents,NumberOfAgents) & NumberOfTrucks > 0 & NumberOfAgents >= 2
<-
	+cnp(Id);
	+job(Id, Items);
	+number_of_tasks(.length(ListItems)+.length(ListToolsNew)+1,Id);
	?task_id(TaskIdA);
	-+task_id(TaskIdA+1);
//	.print("Creating cnp for assemble task ",Storage," free trucks[",NumberOfTrucks,"]: ",FreeTrucks);
	!!announce(assemble(Storage, Items),Deadline,NumberOfTrucks,Id,TaskIdA,FreeAgents,FreeTrucks);
	for ( .member(item(ItemId,Qty),ListToolsNew) ) {
		?task_id(TaskId);
		-+task_id(TaskId+1);
//		.print("Creating cnp for tool task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
		!!announce(tool(ItemId),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
	}
	for ( .member(item(ItemId,Qty),ListItems) ) {
		?task_id(TaskId);
		-+task_id(TaskId+1);
//		.print("Creating cnp for buy task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
		!!announce(item(ItemId,Qty),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
	}
	.
//+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items)
//	: not cnp(Id) & initiator::free_trucks(FreeTrucks) & .length(FreeTrucks,NumberOfTrucks) & initiator::free_agents(FreeAgents) & .length(FreeAgents,NumberOfAgents) & NumberOfTrucks > 0 & NumberOfAgents >= 2
//<-
//	.wait(500);
//	!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
//	.
+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items) 
<- 	
	-action::hold_action(Id);
	if (initiator::mission(JobId, _, _, _, _, _)) { -eval(JobId); }
	!update_free;
	!evaluation_auction::has_set_to_free;
	.print(Id," is no longer viable");
	
	.

+!announce(Task,Deadline,NumberOfAgents,JobId,TaskId,FreeAgents,FreeTrucks)
	: true
<- 
	.concat("cnp_board_",TaskId,CNPBoardName);
//	.print("Creating task ",CNPBoardName);
	makeArtifact(CNPBoardName, "cnp.ContractNetBoard", [Task, Deadline, NumberOfAgents]);
	if (.substring("assemble",Task)) { !send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId); }
	else { !send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId); }
//	.print("Created cnp ",CNPBoardName," for task ",Task);
	getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
//		.print("Got bids (",.length(Bids),") for task #",Qty," ",ItemId," Bids: ",Bids);
		+bids(Task,Bids,JobId);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		?metrics::noBids(NoBids);
		-+metrics::noBids(NoBids+1);
		+bids(Task,[bid(99999,99999,99999,Task,TaskId)],JobId);
	}
	remove[artifact_name(CNPBoardName)];
	.
	
@sendfreetrucks[atomic]
+!send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeTrucks) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.
@sendfreeagents[atomic]
+!send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeAgents) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.
	
@selectBids[atomic]
+bids(_,_,JobId)
	: .count(initiator::bids(_,_,JobId),NumberOfBids) & number_of_tasks(NumberOfTasks,JobId) & NumberOfBids == NumberOfTasks & .my_name(Me)
<-
//	.print("Received all bids ",JobId);
	-number_of_tasks(NumberOfTasks,JobId);
	for ( initiator::bids(assemble(StorageId,_),Bids,JobId) ) {
		if ( not initiator::impossible_task(JobId) ) {
			-bids(assemble(StorageId,_),Bids,JobId);
			?default::select_bid_assemble(Bids,bid(99999,99999),bid(Agent,Distance));
			if (Distance \== 99999) {
//				.print("Awarding assemble of ",JobId," to ",Agent);
				?initiator::job(JobId, Items);
				getLoad(Agent,Load);
				?default::total_load(Items,0,Volume);
				addLoad(Agent,Load-Volume);
				+awarded_assemble(Agent,Items,StorageId,[],JobId,0);
			}
			else { +initiator::impossible_task(JobId); .print("Unable to allocate assemble to deliver at ",StorageId); }
		}
	}
	if ( not initiator::impossible_task(JobId) ) {
		for ( initiator::bids(tool(ItemId),Bids,JobId) ) {
			if ( not initiator::impossible_task(JobId) ) {
				-bids(tool(ItemId),Bids,JobId);
				?default::select_bid_tool(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
				if (Distance \== 99999) {
					getLoad(Agent,Load);
					?default::item(ItemId,Volume,_,_);
			    	addLoad(Agent,Load-Volume);
		//	    	.print("Awarding ",ItemId," to ",Agent," at",Shop);
					if (Distance > 10) { NewTaskCount =  1 }
				    else { NewTaskCount = 0 }
					if (awarded_assemble(Agent,Items,StorageId,AssTaskList,JobId,AssTaskCount)) {
				    	-awarded_assemble(Agent,Items,StorageId,AssTaskList,JobId,AssTaskCount);
				    	.concat(AssTaskList,[tool(ItemId)],NewAssTaskList);
				    	+awarded_assemble(Agent,Items,StorageId,NewAssTaskList,JobId,AssTaskCount+NewTaskCount);
					}
					else {
						if (not initiator::awarded(Agent,_,_,_,_)) {
							+awarded(Agent,Shop,[tool(ItemId)],JobId,NewTaskCount);
						}
						else {
							?awarded(Agent,_,List,JobId,TaskCount);
				    		-awarded(Agent,_,List,JobId,TaskCount);
				    		.concat(List,[tool(ItemId)],NewList);
				    		+awarded(Agent,Shop,NewList,JobId,TaskCount+NewTaskCount);
						}
					}
				}
				else { +initiator::impossible_task(JobId); .print("Unable to allocate tool ",ItemId); }
			}
		}
		for ( initiator::bids(item(ItemId,Qty),Bids,JobId) ) {
			if ( not initiator::impossible_task(JobId) ) {
				-bids(item(ItemId,Qty),Bids,JobId);
				?default::select_bid(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
				if (Distance \== 99999) {
					getLoad(Agent,Load);
					?default::item(ItemId,Volume,_,_);
			    	addLoad(Agent,Load-Volume*Qty);
		//	    	.print("Awarding #",Qty," of ",ItemId," to ",Agent," at",Shop);
					if (Distance > 10) { NewTaskCount =  1 }
				    else { NewTaskCount = 0 }
					if (awarded_assemble(Agent,Items,StorageId,AssTaskList,JobId,AssTaskCount)) {
				    	-awarded_assemble(Agent,Items,StorageId,AssTaskList,JobId,AssTaskCount);
				    	.concat(AssTaskList,[item(ItemId,Qty)],NewAssTaskList);
				    	+awarded_assemble(Agent,Items,StorageId,NewAssTaskList,JobId,AssTaskCount+NewTaskCount);
					}
					else {
						if (not initiator::awarded(Agent,_,_,_,_)) {
							+awarded(Agent,Shop,[item(ItemId,Qty)],JobId,NewTaskCount);
						}
						else {
							?awarded(Agent,_,List,JobId,TaskCount);
				    		-awarded(Agent,_,List,JobId,TaskCount);
				    		.concat(List,[item(ItemId,Qty)],NewList);
				    		+awarded(Agent,Shop,NewList,JobId,TaskCount+NewTaskCount);
						}
					}
				}
				else { +initiator::impossible_task(JobId); .print("Unable to allocate #",Qty," of ",ItemId); }
			}
		}
	}
	if (not initiator::impossible_task(JobId)) {
		if (default::auction(JobId,_,_,_,_,_,_,_,_)){			
			?awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId,AssTaskCount);
			
			?initiator::free_trucks(FreeTrucksA);			
			.delete(AgentA,FreeTrucksA,FreeTrucksNewA);			
			-+initiator::free_trucks(FreeTrucksNewA);
			+::free_trucks_auction(JobId,[AgentA]);
			
			?initiator::free_agents(FreeAgentsA);
			.delete(AgentA,FreeAgentsA,FreeAgentsNewA);
			-+initiator::free_agents(FreeAgentsNewA);
			+::free_agents_auction(JobId,[AgentA]);
			
			for ( initiator::awarded(Agent,Shop,List,JobId,TaskCount) ) {
				?initiator::free_agents(FreeAgents);
				.delete(Agent,FreeAgents,FreeAgentsNew);
				-+initiator::free_agents(FreeAgentsNew);
				
				?::free_agents_auction(JobId,FreeAgentsAuction);
				.concat([Agent],FreeAgentsAuction,FreeAgentsAuctionNew);
				-::free_agents_auction(JobId,FreeAgentsAuction);
				+::free_agents_auction(JobId,FreeAgentsAuctionNew);
				
				?initiator::free_trucks(FreeTrucks);
				if (.member(Agent,FreeTrucks)) {
					.delete(Agent,FreeTrucks,FreeTrucksNew);
					-+initiator::free_trucks(FreeTrucksNew);
					
					?::free_trucks_auction(JobId,FreeTrucksAuction);
					.concat([Agent],FreeTrucksAuction,FreeTrucksAuctionNew);
					-::free_trucks_auction(JobId,FreeTrucksAuction);
					+::free_trucks_auction(JobId,FreeTrucksAuctionNew);
				}
			}
			-cnp(JobId);			
			!evaluation_auction::send_a_bid(JobId);
		}

		else{
			?default::joined(org,OrgId);
//			.print("Creating scheme for ",JobId);
			if (not initiator::awarded(_,_,_,JobId,_)) {
				!create_scheme(JobId, oneagent, SchArtId,OrgId);
			}
			else { !create_scheme(JobId, st, SchArtId,OrgId); }
//			debug(inspector_gui(on))[artifact_id(SchArtId)];
			?awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId,AssTaskCount);
			-awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId,AssTaskCount);
			?initiator::free_agents(FreeAgentsA);
			?initiator::free_trucks(FreeTrucksA);
			.delete(AgentA,FreeTrucksA,FreeTrucksNewA);
			-+initiator::free_trucks(FreeTrucksNewA);
			.delete(AgentA,FreeAgentsA,FreeAgentsNewA);
			-+initiator::free_agents(FreeAgentsNewA);
			for ( initiator::awarded(Agent,Shop,List,JobId,TaskCount) ) {
				?initiator::free_agents(FreeAgents);
				.delete(Agent,FreeAgents,FreeAgentsNew);
				-+initiator::free_agents(FreeAgentsNew);
				?initiator::free_trucks(FreeTrucks);
				if (.member(Agent,FreeTrucks)) {
					.delete(Agent,FreeTrucks,FreeTrucksNew);
					-+initiator::free_trucks(FreeTrucksNew);
				}
				.send(Agent,tell,winner(List,assist(Storage,AgentA,JobId)));
				-awarded(Agent,Shop,List,JobId,TaskCount);	
//				.print(Agent," ",AgentA," ",List);
			}
//			.print(AgentA," ",Items);
			.send(AgentA,tell,winner(Items,assemble(Storage,JobId,AssTaskList)));
			if (initiator::mission(JobId, _, _, _, _, _)) { -initiator::mission(JobId, _, _, _, _, _); -eval(JobId); }
			if (default::winner(_,assist(_,_,JobId))) {
				.drop_desire(action::commitAction(_));
//				?default::actionID(Step);
				if (action::action(Step)) {
					.wait( default::actionID(S2) & S2 \== Step );
				}
			}
			resetLoads;
			-cnp(JobId);
		}
	}
	else { 
		-impossible_task(JobId);
		-cnp(JobId);
		-job(JobId, _);
		-awarded_assemble(_,_,_,_,JobId,_);
		-eval(JobId);
		.abolish(initiator::bids(_,_,JobId));
		.abolish(initiator::awarded(_,_,_,JobId,_));
		.print("Impossible job ",JobId,", aborting it.");
	}
	resetLoads;
	-action::hold_action(JobId);
	!evaluation_auction::has_set_to_free;
	.print("Task allocation is done ",JobId);
	.
+!create_scheme(JobId, SchId, SchArtId,OrgId) <- org::createScheme(JobId, SchId, SchArtId)[wid(OrgId)].
-!create_scheme(JobId, SchId, SchArtId,OrgId) 
<-
	resetLoads;
	-impossible_task(JobId);
	-cnp(JobId);
	-job(JobId, _);
	-awarded_assemble(_,_,_,_,JobId,_);
	-eval(JobId);
	.abolish(initiator::bids(_,_,JobId));
	.abolish(initiator::awarded(_,_,_,JobId,_));
	.print("Bug with create scheme for ",JobId,", detected, aborting it.");
	-action::hold_action(JobId);
	.

@addAgentFree[atomic]
+!add_agent_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
@addTruckFree[atomic]
+!add_truck_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	-+initiator::free_trucks([Agent|FreeTrucks]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
@addMeFree[atomic]
+!add_myself_to_free
	: initiator::free_agents(FreeAgents) & .my_name(Me)
<-
	-+initiator::free_agents([Me|FreeAgents]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
	
@jobFinished[atomic]	
+!job_finished(JobId) 
<- 
	-initiator::job(JobId, _);
	?metrics::completedJobs(C);
	-+metrics::completedJobs(C+1);
//	?estimate(JobId,Start,Estimate);
//	?default::step(Step);
//	.print("Finished job ",JobId," at step ",Step," estimated to end in ",Start+Estimate);
//	-estimate(JobId,Start,Estimate);
	.
@auctionFinished[atomic]	
+!auction_finished(JobId) 
<- 
	-initiator::job(JobId, _);
	?metrics::completedAuctions(C);
	-+metrics::completedAuctions(C+1);
	.

@missionFinished[atomic]	
+!mission_finished(JobId) 
<- 
	-initiator::job(JobId, _);
	?metrics::completedMissions(C);
	-+metrics::completedMissions(C+1);
//	?estimate(JobId,Start,Estimate);
//	?default::step(Step);
//	.print("Finished job ",JobId," at step ",Step," estimated to end in ",Start+Estimate);
//	-estimate(JobId,Start,Estimate);
	.
	
@upateJobEval[atomic]
+!update_eval
	: metrics::failedEvalJobs(C)
<-
	-+metrics::failedEvalJobs(C+1);
.

@upateJobFree[atomic]
+!update_free
	: metrics::failedFreeJobs(C)
<-
	-+metrics::failedFreeJobs(C+1);
.

@upateJobFail[atomic]
+!update_job_failed
	: metrics::failedJobs(C)
<-
	-+metrics::failedJobs(C+1);
	.
@upateMissionFail[atomic]
+!update_mission_failed(FineNew)
	: metrics::failedMissions(C) & metrics::finePaid(OldFine) 
<-
	-+metrics::failedMissions(C+1);
	-+metrics::finePaid(OldFine+FineNew);
	.
@upateAuctionFail[atomic]
+!update_auction_failed(FineNew)
	: metrics::failedAuctions(C) & metrics::finePaid(OldFine) 
<-
	-+metrics::failedAuctions(C+1);
	-+metrics::finePaid(OldFine+FineNew);
	.

//+default::step(End)
//	: initiator::mission(Id, _, _, End, _, Fine) | initiator::failed_mission(Id, End, Fine)
//<-
//	.print("!!!!!!!!!!!!!!!!! Mission ",Id," failed: deadline.");
//	-initiator::mission(Id, _, _, End, _, Fine);
//	-initiator::failed_mission(Id, End, Fine);
//	!update_mission_failed(Fine);
//	.
+default::step(End)
	: initiator::mission(_,_,_,End,_,_) | initiator::failed_mission(_,End,_) | default::auction(_,_,_,_,End,_,_,_,_)
<-
	!check_failed_fined_job(End);
	.
	
+!check_failed_fined_job(End)
	: initiator::mission(Id, _, _, End, _, Fine) | initiator::failed_mission(Id, End, Fine)
<-
	.print("!!!!!!!!!!!!!!!!! Mission ",Id," failed: deadline.");
	-initiator::mission(Id, _, _, End, _, Fine);
	-initiator::failed_mission(Id, End, Fine);
	!update_mission_failed(Fine);
	.
+!check_failed_fined_job(End)
	: default::auction(Id,_,_,_,End,Fine,_,_,_) 
<-
	.print("!!!!!!!!!!!!!!!!! Auction ",Id," failed: deadline.");
	!update_auction_failed(Fine);
	.
	
// debugging
+default::step(998)
	: default::money(Money)
<-	
	-+metrics::money(Money);
.