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
	
	!estimates::compound_estimate(Items);
	if (Items \== []) { 
		.print("@@@@@@@@@@@@@@@@@@@@@ We have items to assemble ",Items); 
		.term2string(Items,ItemsS);
		
		!allocate_tasks(none,Items,Storage);		
	}
	else { 
		.print("££££££££££ Can't assemble anything yet."); 
//		-::must_check_compound;
	}
	-action::reasoning_about_belief(Storage);
	-::must_check_compound;
 	.
 	
 +!allocate_tasks(Id,Task,DeliveryPoint)
	: .findall(Agent,default::play(Agent,Role,_) & (Role==gatherer|Role==explorer_drone),ListAgents)
<-     .print(ListAgents,Task);
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
@priced_job[atomic]
+default::job(Id,Storage,Reward,Start,End,Items)
	: default::step(S) & S >= 11
<-
	
	+action::reasoning_about_belief(Id);
 	.print("Received ",Id,", Items ",Items," starting the priced job process.");
 	!compound_item_quantity(Items);
 	
	!!accomplished_priced_job(Id,Storage,Items);
//	-action::reasoning_about_belief(Id);
	.
+!accomplished_priced_job(Id,Storage,Items)
//	: not entroo
<-
//	+entroo;
//	?default::joined(vehicleart,IdT);
//	addAvailableItem(storage0,item5,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item6,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item7,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item8,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item9,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item10,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
//	addAvailableItem(storage0,item11,10)[wid(IdT)]; // pode ser util para fazer os testes da aloção do assemble
	!estimates::priced_estimate(Id,Items);
//	+entroo;
	.print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ ",Id," is feasible! ");
    !allocate_delivery_tasks(Id,Items,Storage);
    -action::reasoning_about_belief(Id);
    .
-!accomplished_priced_job(Id,Storage,Items)[error_msg(Message)]
<-
	.print(Id," cannot be accomplished! Reasons: ",Message);
	-action::reasoning_about_belief(Id);
    .
 

+!allocate_delivery_tasks(JobId,Tasks,DeliveryPoint)
	: .findall(Agent,default::play(Agent,Role,_) & (Role==gatherer|Role==explorer),ListAgents)
<-     
	!cnpd::announce(delivery_task(DeliveryPoint,Tasks),10000,JobId,ListAgents,CNPBoardName);
     
    getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {	
		!cnpd::evaluate_bids(Tasks,Bids);
       
    	!cnpd::award_agents(JobId,DeliveryPoint,Winners);
    	.print("&&& Winners for ",CNPBoardName,": ",Winners);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		.fail(noBids);
	}      
       
    !cnpd::enclose(CNPBoardName);
    .
    


	