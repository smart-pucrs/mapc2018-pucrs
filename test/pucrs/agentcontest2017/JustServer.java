package pucrs.agentcontest2017;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.Server;


public class JustServer {

	@Before
	public void setUp() {
		try {
			Server.main(new String[] {"-conf", "conf/1simConfig-TeamB.json", "--monitor"});					
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Test
	public void run() {
	}

}
