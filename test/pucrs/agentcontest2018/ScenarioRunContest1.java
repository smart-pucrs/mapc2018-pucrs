package pucrs.agentcontest2018;

import java.io.File;
import java.io.IOException;

import org.apache.commons.io.FileUtils;
import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.Server;


public class ScenarioRunContest1 {
	
	@Before
	public void cleanUpFolders() throws IOException {

		File currentDir = new File("");
		String path = currentDir.getAbsolutePath();	
				
		ScenarioRun1simParis deletefiles = new ScenarioRun1simParis();
		deletefiles.delete(5, path + "\\logs");
		deletefiles.delete(5, path + "\\log");
		deletefiles.delete(5, path + "\\replays");	
		
	}
	
	public void delete(long nFiles, String directoryFolder) throws IOException {
		
		File currentDir = new File("");
		String path = currentDir.getAbsolutePath();	
		
		File folder = new File(directoryFolder);
		
		if(folder.exists()) {
			File[] listFiles = folder.listFiles();
			String[] filesInDir = folder.list();			
			for ( int i=0; i < listFiles.length - nFiles ; i++ ){
				listFiles[i].delete();
				FileUtils.deleteDirectory(listFiles[i]);				
			}		
		}
		
	}

	@Before
	public void setUp() {

		try {			
			JaCaMoLauncher.main(new String[] {"pucrs-mapc2018-contest1.jcm"});
		} catch (JasonException e) {
			System.out.println("Exception: "+e.getMessage());
			e.printStackTrace();
		}

	}

	@Test
	public void run() {
	}

}
