+!go_trade(Item,Qty)
	: new::shopList(SList) & rules::closest_facility(SList, Shop)
<-
	!action::goto(Shop);
	!action::trade(Item,Qty);
	-bidder::winner(_,_,_,_,_,_,_,_,_)[source(_)];
	!strategies::change_role(gatherer,worker);
	.send(vehicle1,achieve,initiator::add_agent_to_free(Role));
	!!strategies::free;
	.