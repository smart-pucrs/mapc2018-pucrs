+!kill_yourself
<-
	.print("The devil has come into my mind");
	!action::forget_old_action;
	!revive;
	.
	
+!revive
	: .my_name(Me) & default::play(Me,PastRole,g1) & strategies::should_become(NewRole)
<-
	.print("Coming back to life");
	!forget_the_past;
	!strategies::change_role(PastRole,NewRole);
	!strategies::go_back_to_work;
	.	

+!forget_the_past
<-
	-strategies::winner(_,_,_,_,_);
	-strategies::winner(_,_,_);
	
	!action::clean_route;
	
//	initiator
	.abolish(_::final_qty_item(_,_));
//	cnp_assemble
	.abolish(_::selected_bids(_));
	.abolish(_::awarded_agent(_,_,_,_,_));
	.abolish(_::constraint_role(_,_));
	.abolish(_::selected_task(_,_,_,_));
//	cnp_delivery
	.abolish(_::selected_bids(_));
	.abolish(_::awarded_agent(_,_,_));
	.abolish(_::selected_task(_,_,_));
//	estimate
	.abolish(_::partial_stock(_,_));
	.abolish(_::must_assemble(_,_));
	
	.abolish(action::_);
	+action::current_token(0);
	
//	reasoning
	.abolish(action::reasoning_about_belief(_));
	.