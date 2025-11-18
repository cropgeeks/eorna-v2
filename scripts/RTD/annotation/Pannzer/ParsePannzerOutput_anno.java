package utils.go;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import utils.entities.Gene;
import utils.entities.Transcript;

//class for parsing the main anno.out file from Pannzer
public class ParsePannzerOutput_anno
{

	static final String USAGE = "java utils.go.ParsePannzerOutput_anno <anno.out file from PANNZER> <output prefix> <gene ID regex> <transcript ID regex>";
	
	static HashMap<String,Gene> geneLookup = new HashMap<String, Gene>();
	static HashMap<String,Transcript> transcriptLookup = new HashMap<String, Transcript>(); 
	
	//stores all GO IDs (key) and their annotation strings (value) that we find in the input dataset
	static HashMap<String, String> goAnnotations = new HashMap<String, String>();
	
	static HashMap<String,TreeSet<String>> goGeneLists = new HashMap<String, TreeSet<String>>();
	
	static int transcriptCount = 0;
	static int geneCount = 0;
	
	static String geneIDRegex;
	static String transcriptIDRegex;

	//##############################################################################
	
	public static void main(String[] args)
	{
		if(args.length != 4)
		{
			System.err.println("ERROR: incorrect number of arguments supplied. Usage:\n" + USAGE);
			System.exit(1);
		}
				
		File inputFileAnno = new File(args[0]);
		File outputFile = new File(args[1] + ".txt");
		File transcriptAnnoFile = new File(args[1] + ".transcriptAnno.txt");
		File gmtFile = new File(args[1] + ".gmt");
		
		geneIDRegex = args[2];
		transcriptIDRegex = args[3];
		
		try
		{
			parseAnnoFile(inputFileAnno);
			reFormatData(outputFile);
			outputTranscriptAnnotation(transcriptAnnoFile);
			outputGMTFile(gmtFile);
			
			System.out.println("processed " + geneCount + " genes with " + transcriptCount + " transcripts");
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
	private static void outputGMTFile(File gmtFile) throws IOException
	{
		BufferedWriter writer = new BufferedWriter(new FileWriter(gmtFile)); 

		//for every GO ID we have
		for(String goID : goGeneLists.keySet())
		{
			//write the GO ID to file
			writer.write(goID + "\t");
			
			//write the description to file
			writer.write(goAnnotations.get(goID) + "\t");
			
			TreeSet<String> geneList = goGeneLists.get(goID);
			//for every gene associated with this GO ID
			for(String geneName : geneList)
			{
				//write the gene ID to file
				writer.write(geneName + "\t");
			}
			
			//EOL
			writer.newLine();
		}
		
		writer.close();
	}

	//--------------------------------------------------------------------------------------------------------------------------------

	private static void reFormatData(File outputFile) throws IOException
	{
		BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile)); 
		
		for(Gene gene : geneLookup.values())
		{		
			//output  gene name
			writer.write(gene.name + "\t");			
			
			//output annotation
			if(gene.annotationSet.size() == 0)
				writer.write("" + "\t");
			else
			{
				for(String annot : gene.annotationSet)				
					writer.write(annot + ";");
				writer.write("" + "\t");
			}
			
			//write all the GO codes into one field
			for(String goID : gene.goAnnotations.keySet())
			{
				writer.write(goID + ";");
			}
			writer.write("\t");
			
			//then write all the corresponding GO strings into another field 
			for(String goID : gene.goAnnotations.keySet())
			{
				writer.write(gene.goAnnotations.get(goID) + ";");
			}
			writer.write("\n");
		}
		
		writer.close();
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	//this outputs transcript-level annotation, one line per transcript
	private static void outputTranscriptAnnotation(File transcriptAnnoFile) throws IOException
	{
		BufferedWriter writer = new BufferedWriter(new FileWriter(transcriptAnnoFile)); 
		
		for(Transcript transcript : transcriptLookup.values())
		{		
			//output  tr. name
			writer.write(transcript.name + "\t");			
			
			//output annotation
			if(transcript.annotationSet.size() == 0)
				writer.write("" + "\t");
			else
			{
				for(String annot : transcript.annotationSet)				
					writer.write(annot + ";");
				writer.write("" + "\t");
			}
			
			//write all the GO codes into one field
			for(String goID : transcript.goAnnotations.keySet())
			{
				writer.write(goID + ";");
			}
			writer.write("\t");
			
			//then write all the corresponding GO strings into another field 
			for(String goID : transcript.goAnnotations.keySet())
			{
				writer.write(transcript.goAnnotations.get(goID) + ";");
			}
			writer.write("\n");
		}
		
		writer.close();
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	/**
	 * Method for parsing the main anno.out file from Pannzer
	 * Format looks like this:
	 * 
qpid 	type	score	PPV	id	desc
lcl|ORF1_BART1_0-p00982.001:147:407	BP_ARGOT	11.16623471	0.789899107	9611	 response to wounding

	 */
	private static void parseAnnoFile(File inputFileGO) throws IOException
	{
		BufferedReader reader = new BufferedReader(new FileReader(inputFileGO));

		String line = null;

		//read header and ignore
		reader.readLine();

		//read the rest of the file
		while((line= reader.readLine()) != null)
		{
			String [] tokens = line.split("\t");
			
//			System.out.println(line);
			
			//extract the gene string
			String geneID = tokens[0];					
			//get the gene name from this and retrieve or create new gene object
			String geneName = getIDFromString(geneID, geneIDRegex);
			Gene gene = getGene(geneName);	
			
			//also add the transcript to the gene's transcript list
			String transcriptName = getIDFromString(geneID,transcriptIDRegex);		
			Transcript transcript = gene.transcripts.get(transcriptName);
			if(transcript == null)
			{
				transcript = new Transcript();
				transcript.name = transcriptName;
				gene.transcripts.put(transcriptName,transcript);
				transcriptCount++;
				//System.out.println("adding transcript " + transcript.name);
			}	
			//also add the transcript to our global lookup
			transcriptLookup.put(transcriptName, transcript);
			
			//find out the type of entry
			String entryType = tokens[1];
			//we have: 
//			BP_ARGOT
//			CC_ARGOT
//			DE
//			EC_ARGOT
//			GN
//			KEGG_ARGOT
//			MF_ARGOT
//			original_DE
//			qseq
			
			//this is the textual description for a transcript
			//looks like this:
			//lcl|ORF49_BART1_0-p12574.015:4799:6454	DE	0.935363389	0.477326976	0.9	Chloride channel protein CLC-c
			if(entryType.equals("DE") || entryType.equals("GN"))
			{
				//add the annotation to the gene, and separately the transcript
				//by adding the annotation to a set we solve the issue of potentially different annotations for this gene from alternative transcripts
				gene.annotationSet.add(tokens[5]);		
				transcript.annotationSet.add(tokens[5]);	
			}
			//these entries represent GO terms, classified by top level GO category
			else if (entryType.startsWith("BP_") || entryType.startsWith("CC_") || entryType.startsWith("MF_"))
			{
				//and the GO annotations
				String goID = "GO:" + leftPad(tokens[4], 7);
				String goDescription = tokens[5];
				//add them to this gene and the transcript
				//this adds them to a hashmap where the GO ID is the key, so we can't accidentally add a term twice
				gene.goAnnotations.put(goID, goDescription);
				transcript.goAnnotations.put(goID, goDescription);	
				//we also keep a local list of the full set of terms encountered -- add it to this too
				goAnnotations.put(goID, goDescription);

				//add the gene to the gene list for this GO ID
				TreeSet<String> geneList = goGeneLists.get(goID);
				//if we don't have a gene list yet, we need to create one
				if(geneList == null)
				{
					geneList = new TreeSet<String>();		
					goGeneLists.put(goID, geneList);
				}
				geneList.add(gene.name);
			}
		}
		reader.close();		
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
	//extracts the transcript/gene name from a longer string based on a regex
	private static String getIDFromString(String str, String regex)
	{
		String id = "";
	
		try
		{
			//extract the gene name from the longer ID string using a regex	
			 Pattern p = Pattern.compile(regex);
			 Matcher m = p.matcher(str);	
			 m.find();
			id = str.substring(m.start(), m.end());
		}
		//this is thrown when a contig/chromosome name doesn't match our regex   
		catch (java.lang.IllegalStateException e)
		{
		}		

		return id;
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
	private static Gene getGene(String geneName)
	{	
		//retrieve this gene or make a new one
		Gene gene = geneLookup.get(geneName);
		//check whether we have this gene already
		if(gene == null)
		{
			gene = new Gene();
			gene.name = geneName;
			geneLookup.put(geneName, gene);
			geneCount++;
		}
		
		return gene;
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
	private static Transcript getTranscript(String transcriptName)
	{	
		//retrieve this gene or make a new one
		Transcript transcript = transcriptLookup.get(transcriptName);
		//check whether we have this gene already
		if(transcript == null)
		{
			transcript = new Transcript();
			transcript.name = transcriptName;
			transcriptLookup.put(transcriptName, transcript);
			transcriptCount++;
		}
		
		return transcript;
	}
	
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
	private static String leftPad(String number, int numDigits)
	{	
		StringBuilder sb = new StringBuilder();
		
		//first need to find out how long the number is already 
		//want it padded to at most numDigits		
		for (int  i = number.length(); i < numDigits; i++)
		{
			sb.append("0");
		}
		sb.append(number);
		
		return sb.toString();
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------
	
}
