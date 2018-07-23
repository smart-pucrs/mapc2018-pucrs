+default::winner(Item,Base,Mode)
//	: default::joined(org,OrgId)
<-
//	lookupArtifact(JobId,SchArtId)[wid(OrgId)];
//	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the task to assemble ",Item," mode: ",Mode);
//	org::commitMission(massist)[artifact_id(SchArtId)];
	.