+!go_store
	: bidder::winner(_,_,Qty,Item,_,_,Storage,_,_)  & default::role(Role, _, _, _, _, _, _, _, _, _, _)
<-
	!action::goto(Storage);
	!action::store(Item,Qty);
	addAvailableItem(Storage,Item,Qty);
	-bidder::winner(_,_,_,_,_,_,_,_,_)[source(_)];
	.send(vehicle1,achieve,initiator::add_agent_to_free(Role));
	!!strategies::free;
	.