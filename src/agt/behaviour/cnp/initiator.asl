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
+default::baseStored
	: not ::must_check_compound  & strategies::centerStorage(Storage)
<-
	+::must_check_compound;
	.print("Chamou o Based Stored");
	.wait({+default::actionID(_)});
	+action::reasoning_about_belief(Storage);
	
	!pick_task(evaluate_compound_item(Storage))[priority(4)];
	
	-action::reasoning_about_belief(Storage);
	-::must_check_compound;
 	.
+!evaluate_compound_item(Storage)
<-
	!estimates::compound_estimate(Items);
	if (Items \== []) { 
		.print("@@@@@@@@@@@@@@@@@@@@@ We have items to assemble ",Items); 		
		!allocate_tasks(none,Items,Storage);		
	}
	else { 
		.print("££££££££££ Can't assemble anything yet."); 
	}
	.
 	
 +!allocate_tasks(Id,Task,DeliveryPoint)
	: .findall(Agent,default::play(Agent,Role,g1) & (Role==gatherer|Role==explorer_drone),ListAgents)
<-    
	announce(assemble(Task),10000,ListAgents,CNPBoardName);
       
    getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
		!cnpa::evaluate_bids(Id,Task,Bids);
       
	    !cnpa::award_agents(CNPBoardName,DeliveryPoint,Winners);
	    .print("### Winners for ",CNPBoardName,": ",Winners);
	    award(Winners);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
//		.fail(noBids);
	} 
	clear(CNPBoardName);  
    .

// ### PRICED JOBS ###
//job(id, storage, reward, start, end, [required(name1, qty1), ...])
@priced_job[atomic]
+default::job(Id,Storage,Reward,Start,End,Items)
	: default::step(S) & S >= 11
<-	
	+action::reasoning_about_belief(Id);
 	.print("Received ",Id,", Items ",Items," starting the priced job process.");
 	!compound_item_quantity(Items);
 	
//	!!accomplished_job(Id,Storage,Items);
	!!pick_task(accomplished_job(Id,Storage,Items))[priority(3)];
//	-action::reasoning_about_belief(Id);
	.
	
// ### MISSION ###
// mission(id, storage, reward, start, end, fine, bid, time, [required(name1, qty1), ...])
@mission[atomic]
+default::mission(MissionId,Storage,Reward,_,End,Fine,_,_,Items)
<-
	+::mission(MissionId,Storage,Reward,End,Fine,Items);
	.print("Receveid a new Mission ",MissionId," to be delivered at ",Storage," R: ",Reward," F: ",Fine," Items: ",Items);
	!mission_done;
	.
@compound_stored[atomic]
+default::compound_stored
<-
	!mission_done;
	.
+!mission_done
	: default::step(S)
<-
	for(::mission(MissionId,Storage,Reward,End,Fine,Items) & not action::reasoning_about_belief(MissionId)){
		if (S+30 <= End){
			+action::reasoning_about_belief(MissionId);
			.print("Thinking about mission ",MissionId);
			!!pick_task(accomplished_job(MissionId,Storage,Items))[priority(1)];
		} else{
			.print("Mission ",MissionId," cannot be accomplished anymore, step ",S," end ",End,", we'll pay the fine ",Fine);
			-::mission(MissionId,_,_,_,_,_);
		}		
	}	
	.
	
+!accomplished_job(Id,Storage,Items)
<-
	!estimates::priced_estimate(Id,Items);
	.print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ ",Id," is feasible! ");
    !allocate_delivery_tasks(Id,Items,Storage);
    -action::reasoning_about_belief(Id);
    .
-!accomplished_job(Id,Storage,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	-action::reasoning_about_belief(Id);
    .

+!allocate_delivery_tasks(JobId,Tasks,DeliveryPoint)
	: .findall(Agent,default::play(Agent,Role,g1) & (Role==gatherer|Role==explorer),ListAgents)
<-     
	!cnpd::announce(delivery_task(DeliveryPoint,Tasks),10000,JobId,ListAgents,CNPBoardName);
     
    getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {	
		!cnpd::evaluate_bids(Tasks,Bids);
       
    	!cnpd::award_agents(JobId,DeliveryPoint,Winners);
    	.print("&&& Winners for ",CNPBoardName,": ",Winners);
    	
    	-::mission(JobId,_,_,_,_,_);
//    	-::priced(JobId,_,_,_,_,_);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		.fail(noBids);
	}      
       
    !cnpd::enclose(CNPBoardName);
    .
    
// ### DECIDE WHAT TASK TO ALLOCATE ###
// Priority 1 - Missions
// Priority 2 - Auctions
// Priority 3 - Priced
// Priority 4 - Compound Items
^!pick_task(G)[priority(MyP),state(started)]
	: not ::task_priority(_) | (::task_priority(P) & MyP < P)
<-
	-+::task_priority(MyP);
	.
+!pick_task(G)[priority(MyP)]
	: not ::requesting_help & (not ::task_priority(_) | (::task_priority(P) & MyP <= P))  
<-
	+::requesting_help;
	!G;
	-::task_priority(_);
	-::requesting_help;
	.
+!pick_task(G)[priority(P)]
<-
	.wait({-::requesting_help});
	!pick_task(G)[priority(P)];
	.
 	
    


	