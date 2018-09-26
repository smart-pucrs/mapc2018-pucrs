can_gather(Base) 
:- 
	default::load(Load) & 
	default::item(Base,Vol,_,_) &
	default::maxLoad(Capacity) &
	(Load+Vol) <= Capacity
	.
	
+!initial_gather
	: team::resNode(_,_,_,_)
<-
	?new::resourceList(List);
	?rules::closest_facility(List,ResourceNode);
	!!strategies::gather(ResourceNode);
	.
+!initial_gather
<-
	.print("No resource nodes detected, switching to explorer.")
	!strategies::change_role(gatherer,explorer);
	!explore::go_explore_charging;
	!strategies::change_role(explorer,gatherer);
	!strategies::go_back_to_work;
	.

+!gather(Base,NItem)
	: not default::hasItem(Base,_) | (default::hasItem(Base,NItemNew) & NItemNew < NItem)
<-
	!action::gather;
	!gather(Base,NItem);
	.
+!gather(Base,NItem).

+!gather_full(Base)
	: ::can_gather(Base)
<- 
	!action::gather;
	!gather_full(Base);
	.
+!gather_full(Base).
