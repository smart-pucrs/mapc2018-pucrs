package cnp;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import cartago.AgentId;
import cartago.Artifact;
import cartago.ArtifactConfig;
import cartago.ArtifactId;
import cartago.OPERATION;
import cartago.OpFeedbackParam;
import cartago.OperationException;
import jason.asSemantics.Agent;
import jason.asSyntax.Literal;

public class TaskBoard extends Artifact {
	
	private Logger logger = Logger.getLogger(TaskBoard.class.getName());
	
	private int taskId;
	private Map<String, ArtifactId> cnps = new HashMap<String, ArtifactId>();
	
	void init(){
		logger.info("TaskBoard Artifact created!");
		taskId = 0;
	}
	
	@OPERATION void announce(String taskDescr, int duration, Object[] agents, OpFeedbackParam<String> id){
		taskId++;
		try {
			String artifactName = "cnp_board_"+taskId;
			ArtifactId cnp = makeArtifact(artifactName, "cnp.ContractNetBoard", new ArtifactConfig(taskDescr,duration,agents.length));
			
			Literal[] lAg = new Literal[agents.length];
			for(int i=0;i<agents.length;i++)
				lAg[i] = Literal.parseLiteral(agents[i].toString());
			
			defineObsProperty("task", lAg, Literal.parseLiteral(taskDescr), artifactName, taskId);			
			
			this.cnps.put(artifactName, cnp);
			
			id.set(artifactName);
		} catch (Exception ex){
			logger.info("announce_failed");
		}
	}
//	@OPERATION void announce(String taskDescr, int duration, int agents, OpFeedbackParam<String> id){
//		taskId++;
//		try {
//			String artifactName = "cnp_board_"+taskId;
//			ArtifactId teste = makeArtifact(artifactName, "cnp.ContractNetBoard", new ArtifactConfig(taskDescr,duration,agents));
//			logger.info("teste "+this.getId().getWorkspaceId()+" tes "+teste.getWorkspaceId().toString());
//			defineObsProperty("task", Literal.parseLiteral(taskDescr), artifactName, taskId);
//			id.set(artifactName);
//		} catch (Exception ex){
//			logger.info("announce_failed");
//		}
//	}
	
	@OPERATION void award(Object[] winners){
		Literal[] winner = new Literal[winners.length];
		for(int i=0;i<winners.length;i++) {
			winner[i] = Literal.parseLiteral(winners[i].toString());
			signal(winner[i].getFunctor(),winner[i].getTermsArray());
		}
	}
	
	@OPERATION void clear(String artifactName) throws OperationException{
		this.removeObsPropertyByTemplate("task",null,null,artifactName,null);
		dispose(this.cnps.get(artifactName));
		this.cnps.remove(artifactName);
	}
	
	@OPERATION void generateTaskId(OpFeedbackParam<String> id){
		this.taskId++;
		id.set(String.valueOf(this.taskId));
	}
}