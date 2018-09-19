!kill_an_agent.

+!kill_an_agent
<-
	.send([vehicle26],achieve,reborn::kill_yourself);
	.kill_agent(devil);
	.print("Devil is still alive");
	.

//+!kill_an_agent
//	: .all_names(Agents)
//<-
//	.send(Agents,achieve,reborn::kill_yourself);
//	.kill_agent(devil);
//	.print("Devil is still alive");
//	.