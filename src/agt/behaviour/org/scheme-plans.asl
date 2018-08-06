+goalState(TaskId,task_completed,_,_,satisfied)
	: bidder::winner(_,_,_,_,assemble,_,_,_,_)
<-
   .print("*** all done! ***");
   .term2string(TaskId,TaskIdS);
   removeScheme(TaskIdS);
   .
  
@explorationDone[atomic]
+goalState(TaskId,exploration_completed,_,_,satisfied)
	: .my_name(vehicle1)
<-
	!strategies::not_free;
	.print("*** exploration all done! ***");
	.term2string(TaskId,TaskIdS);
	removeScheme(TaskIdS);
	!initiator::create_item_tasks;
	!initiator::send_free;
   .
@explorationDone2[atomic]
+goalState(_,exploration_completed,_,_,satisfied)
<-
	!strategies::not_free;
   .
   
+!explore
<-
	!explore::go_explore_charging;
	!!strategies::free;
	.
   
+!gather_items
	: bidder::winner(Base,NBase,_,_,_,_,_,Workshop,_)
<-
 	!strategies::not_free;
	!gather::go_gather(Base,NBase);
	.print("Finished gathering.");
	!action::goto(Workshop);
	!!check_state;
	.
	
+!gather_items_assemble
	: bidder::winner(Base,NBase,_,_,_,_,_,Workshop,_)
<-
 	!strategies::not_free;
	!gather::go_gather(Base,NBase);
	.print("Finished gathering.");
	!action::goto(Workshop);
	!!check_state;
	.
	
+!check_state : not goalState(JobId,phase1,_,_,satisfied) <- !!strategies::free.
+!check_state.

+!do_assemble
	: bidder::winner(_,_,Qty,Item,_,_,Storage,Workshop,_)
<-
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
 	.print("Ready to perform the assemble");
	!strategies::not_free;
	!assemble::assemble(Item,Qty);
	!!go_store(Item,Qty,Storage);
	.
	
+!go_store(Item,Qty,Storage)
<-
	!stock::store_items(Item,Qty,Storage);
	-bidder::winner(_,_,_,_,_,_,_,_,_)[source(_)];
	!strategies::change_role(gatherer,worker);
	.send(vehicle1,achieve,initiator::add_agent_to_free(Role));
	!!strategies::free;
	.
	
+!assist_assemble
	: bidder::winner(_,_,_,_,_,Assembler,_,_,_)
<-
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
 	.print("Ready to perform the assist assemble");
	!strategies::not_free;
	+strategies::assembling;
	!!assemble::assist_assemble(Assembler);
	.
	
+!stop_assist_assemble
	: bidder::winner(_,_,_,_,_,_,_,_,_) & default::role(Role, _, _, _, _, _, _, _, _, _, _)
<-
	-strategies::assembling;
	-bidder::winner(_,_,_,_,_,_,_,_,_)[source(_)];
	!strategies::change_role(gatherer,worker);
//	for ( default::hasItem(ItemId,Qty) ) { .print(">>>>>>>>> Assist assemble ended, I have #",Qty," of ",ItemId); }
//	!!strategies::empty_load;
	.send(vehicle1,achieve,initiator::add_agent_to_free(Role));
	!!strategies::free;
	.