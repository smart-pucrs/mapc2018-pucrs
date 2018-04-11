package pucrs.agentcontest2017;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.Server;


public class ScenarioRunContest1 {

	@Before
	public void setUp() {

		try {			
			JaCaMoLauncher.main(new String[] {"pucrs-mapc2017-contest1.jcm"});
		} catch (JasonException e) {
			System.out.println("Exception: "+e.getMessage());
			e.printStackTrace();
		}

	}

	@Test
	public void run() {
	}

}
