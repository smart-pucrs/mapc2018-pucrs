canUpdate(speed) :- speed(Speed) & role(_,_, MaxSpeed,_,_,_,_,_,_,_,_) & (Speed < MaxSpeed) & upgrade(speed, Cost,_) & massium(Massium) & (Cost < Massium).
canUpdate(load) :- maxLoad(Cap) & role(_,_,_,_, MaxLoad,_,_,_,_,_,_) & (Cap < MaxLoad) & upgrade(load, Cost,_) & massium(Massium) & (Cost < Massium).
canUpdate(skill) :- skill(Skill) & role(_,_,_,_,_,_, MaxSkill,_,_,_,_) & (Skill < MaxSkill) & upgrade(skill, Cost,_) & massium(Massium) & (Cost < Massium).
canUpdate(vision) :- vision(Vision) & role(_,_,_,_,_,_,_,_, MaxVision,_,_) & (Vision < MaxVision) & upgrade(vision, Cost,_) & massium(Massium) & (Cost < Massium).
canUpdate(battery) :- maxBattery(Battery) & role(_,_,_,_,_,_,_,_,_,_, MaxBattery) & (Battery < MaxBattery) & upgrade(battery, Cost,_) & massium(Massium) & (Cost < Massium).


+!update(Type)
	: canUpdate(Type) & new::shopList(List) & rules::closest_facility(List, Facility)
<-	
	!action::goto(Facility);
	!action::upgrade(Type);
	.