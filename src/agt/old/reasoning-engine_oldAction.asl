//{begin namespace(engine, local)}
+!commitAction(Action)
	: default::actionID(S) & not action::action(S) & not action::hold_action(_)
<-
	+action::action(S);
//	.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
	if ( Action \== recharge & Action \== continue) {
		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
	}
	action(Action);
	.wait( default::actionID(S2) & S2 \== S );
//	.print("Got out of wait from step ",S);
	?default::lastActionResult(Result);
	.print("Last action result was: ",Result);
//	.wait( default::lastActionResult(Result) );
	-action::action(S);
		
	if (Action \== recharge & Action \== continue & not .substring("deliver",Action) & not .substring("assist_assemble",Action) & not .substring("buy",Action) & not .substring("bid_for_job",Action) & not .substring("gather",Action) & Result \== successful) {
		.print("Failed to execute action ",Action," at step ",S,". Executing it again.");
		!commitAction(Action);
//		.fail(action(Action),result(Result));
	}
	else {
		if (.substring("deliver",Action) & Result == failed ) { !commitAction(Action); }
		if (.substring("deliver",Action) & Result \== failed_job_status & default::winner(_, assemble(_, JobId, _))) { +strategies::jobDone(JobId); }
		if (action::next_action(Action2)) {
			-action::next_action(Action2);
//			.print("Removing next action ",Action2);
		}
		else { 			
			if (strategies::free) { !!action::recharge_is_new_skip; }
		}
	}
	.
+!commitAction(Action) 
	: action::hold_action(_)
<- 
//	.print("Holding action ",Action);
	.wait(50);
//	.print("Trying action ",Action," again now.");
	!commitAction(Action);
	.
+!commitAction(Action) : Action == recharge.
+!commitAction(Action) 
	: Action \== recharge & metrics::next_actions(C) & not action::next_action(_)
<- 
	+action::next_action(Action); 
	-+metrics::next_actions(C+1); 
	.print("Next action ",Action); 
	.wait( {-action::next_action(Action) }); 
	!commitAction(Action);
	.
//+!commitAction(Action) <- .print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ NO ",Action).
//{end}



