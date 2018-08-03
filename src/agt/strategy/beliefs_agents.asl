+winner(JobId,Deliveries,DeliveryPoint)[source(Initiator)]
	: .my_name(Me) & default::play(Me,CurrentRole,_)
<-
	.print("I won the tasks to ",Deliveries," at ",DeliveryPoint);
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!strategies::change_role(CurrentRole,deliveryagent);
	
	!delivery::delivery_job(JobId,Deliveries,DeliveryPoint);
	-winner(JobId,Storage,QtdS,DeliveryPoint)[source(Initiator)];
	!strategies::change_role(deliveryagent,CurrentRole);
	!strategies::always_recharge;
	.