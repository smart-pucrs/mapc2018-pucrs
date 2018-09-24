+!kill_yourself
<-
	.print("The devil has come into my mind");
	.drop_all_intentions;
//	!action::forget_old_action;
	!revive;
	.
	
+!revive
	: .my_name(Me) & default::play(Me,PastRole,g1) & strategies::should_become(NewRole)
<-
	.print("Coming back to life");
	!forget_the_past;
//	.wait(teste);
	!strategies::change_role(PastRole,NewRole);
	.wait({+default::actionID(_)}); // wait for beliefs synchronisation
	!strategies::go_back_to_work;
	.	

+!forget_the_past
<-
	?action::current_token(Token);
	.abolish(action::_);
	+action::current_token(Token);

	.abolish(attack::_);
	
	.abolish(build::_);	
	
	.abolish(cnpa::_);
	
	.abolish(cnpd::_);
	
	.abolish(delivery::_);
	
	.abolish(estimate::_);	
	
	?explore::vLat(VLat);
	?explore::vLon(VLon);
	?explore::vVolta(VV);
	?explore::n_steps(NS);
	?explore::n_walks(NW);
	.abolish(explore::_);
	+explore::n_steps(NS);
	+explore::n_walks(NW);
	+explore::vLat(VLat);
	+explore::vLon(VLon);
	+explore::vVolta(VV);
	
	.findall(mission(MissionId,Storage,Reward,End,Fine,Items),initiator::mission(MissionId,Storage,Reward,End,Fine,Items),MissionList);
	.findall(compound_item_quantity(Item,Qty),initiator::compound_item_quantity(Item,Qty),ItemList);
	.abolish(initiator::_);
	for(.member(compound_item_quantity(Item,Qty),ItemList)){
	   +initiator::compound_item_quantity(Item,Qty);
	}
	for(.member(mission(MissionId,Storage,Reward,End,Fine,Items),MissionList)){
	   +initiator::mission(MissionId,Storage,Reward,End,Fine,Items);
	}
	
	.abolish(gather::_);
	
	?strategies::centerStorage(Storage);
	?strategies::centerWorkshop(Workshop);
	?strategies::should_become(Role);
	.abolish(strategies::_);
	+strategies::should_become(Role);
	+strategies::centerWorkshop(Workshop);
	+strategies::centerStorage(Storage);
	+strategies::team_ready;
	+strategies::noActionCount(0);
	
	.abolish(org::_);
	.
	
+!synchronise_team_artifact_environment
	: strategies::centerStorage(Storage) & default::storage(Storage,_,_,_,_,StoredItems)
<-
	for(.member(item(Item,Qty,_),StoredItems)){
//		if (default::item(Item,_,_,parts([]))){
//			addAvailableItem(Storage,Item,Qty);	
//		}
		addAvailableItem(Storage,Item,Qty);
	}
	.