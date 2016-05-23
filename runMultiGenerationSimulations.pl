#!/usr/bin/perl
#
#Usage:
# ./runSimulations.pl
#
#Author: Jonathan Karr, jkarr@stanford.edu
#Affiliation: Covert Lab, Department of Bioengineering, Stanford University
#Last updated: 1/9/2011

use Cwd;
use Date::Format;
use Date::Language;
use HTML::Entities;
use HTML::Template;
use MIME::Lite;
use strict;
use Switch;
use Sys::Hostname;
use XML::DOM;
require 'library.pl';

#options
my %config = getConfiguration();

my $linuxUser = $config{'fileUserName'};
my $linuxRunUser = $config{'execUserName'};
my $storageServer = $config{'simulationHostName'};
my $nodeTmpDir = $config{'nodeTmpDir'};
my $pathToRunTime = $config{'mcrPath'};
my $emailAddress = $config{'email'};
my $baseDir = $config{'simulationPath'};
my $baseURL = 'http://'.$config{'URL'}.'/simulation';

my $webSVNURL = $config{'webSVNURL'};

my $xmlns = 'http://'.$config{'hostName'};
my $schemaLocation = 'http://'.$config{'hostName'}.' conditions.xsd';

my $outDir = "$baseDir/output/runSimulation";
my $lang = Date::Language->new('English');
my $conditionSetTimeStamp = $lang->time2str("%Y_%m_%d_%H_%M_%S", time);
my $useSeedOffset = 1;

my $firstName = 'Jonathan';
my $lastName = 'Karr';
my $email = 'jkarr@stanford.edu';
my $affiliation = 'Covert Lab, Stanford University';
my $userName = 'jkarr';
my $hostName = 'covertlab-jkarr.stanford.edu';
my $ipAddress = '171.65.92.146';
my $revision = 2576;
my $differencesFromRevision = '';
my $shortDescrip = 'Multi-generation simulation 11/19/2012';
my $longDescrip = 'Multi-generation simulation 11/19/2012';

my $lengthSec = 50000;
my $nGenZero = 8;
my $nGenerations = 8;
my $iGenMin = 0;
my $seedOffset = ($useSeedOffset ? time : 0);
my $maxSimPerGeneration = 128;

#check output directory exists
if (-d $outDir){}
else {die "Output directory doesn't exist";}

#make output directory
if (-d "$outDir/$conditionSetTimeStamp"){}
else{ mkdir "$outDir/$conditionSetTimeStamp" or die "Unable to make directory $outDir/$conditionSetTimeStamp: $!"; }

#compile runSimulation, runReindexing projects
`./build.sh runSimulation`;
`./build.sh runReindexing`;

#copy executables
if (-d "$outDir/$conditionSetTimeStamp/bin"){}
else{ mkdir "$outDir/$conditionSetTimeStamp/bin" or die "Unable to make directory $outDir/$conditionSetTimeStamp/bin: $!"; }
`cp -R bin/runSimulation $outDir/$conditionSetTimeStamp/bin`;
`cp -R bin/runReindexing $outDir/$conditionSetTimeStamp/bin`;

#queue simulations
my $template = HTML::Template->new(filename => 'job.multiGenerationSimulation.sh.tmpl');
$template->param(conditionSetTimeStamp => $conditionSetTimeStamp);
$template->param(linuxRunUser => $linuxRunUser);
$template->param(emailAddress => $emailAddress);
$template->param(outDir => $outDir);
$template->param(storageServer => $storageServer);
$template->param(pathToRunTime => $pathToRunTime);
$template->param(nodeTmpDir => $nodeTmpDir);

my $nJobs = 0;
my $submitJobs = '';
my $prevGenFirstSimIdx = 0;
my $iSimGlobalOff = 0;
for (my $iGen = 0; $iGen < $nGenerations; $iGen++){
	if ($iGen >= $iGenMin){	
		for (my $iSim = 0; $iSim < $nGenZero * (2 ** $iGen); $iSim++){			
			my $iSimGlobal = $iSimGlobalOff + $iSim + 1;

			#create output file, setup output file names
			my $dirName = sprintf("%s/%s/%d", $outDir, $conditionSetTimeStamp, $iSimGlobal);
			if (-d $dirName){}
			else{ mkdir $dirName or die "Unable to make directory $dirName: $!"; }			
			
			#save generation, index within generation
			open(FH, '>', "$dirName/generation.index") or die $!;
			print FH "$iGen\n";
			close(FH);
			
			open(FH, '>', "$dirName/generation.cell.index") or die $!;
			print FH "$iSim\n";
			close(FH);
			
			#output condition xml file
			my $conditionFileName = sprintf("%s/conditions.xml", $dirName);
			open(FH, '>', $conditionFileName) or die $!;
			print FH "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
			print FH "<!--\n";
			print FH "Autogenerated condition set.\n";
			print FH "\n";
			print FH "-->\n";
			print FH "<conditions\n";
			print FH "\txmlns=\"$xmlns\"\n";
			print FH "\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n";
			print FH "\txsi:schemaLocation=\"$schemaLocation\">\n";
			print FH sprintf("\t<firstName><![CDATA[%s]]></firstName>\n", $firstName);
			print FH sprintf("\t<lastName><![CDATA[%s]]></lastName>\n", $lastName);
			print FH sprintf("\t<email><![CDATA[%s]]></email>\n", $email);
			print FH sprintf("\t<affiliation><![CDATA[%s]]></affiliation>\n", $affiliation);
			print FH sprintf("\t<userName><![CDATA[%s]]></userName>\n", $userName);
			print FH sprintf("\t<hostName><![CDATA[%s]]></hostName>\n", $hostName);
			print FH sprintf("\t<ipAddress><![CDATA[%s]]></ipAddress>\n", $ipAddress);
			print FH sprintf("\t<revision><![CDATA[%s]]></revision>\n", $revision);
			print FH sprintf("\t<differencesFromRevision><![CDATA[%s]]></differencesFromRevision>\n", encode_entities($differencesFromRevision));
			print FH sprintf("\t<condition>\n");
			print FH sprintf("\t\t<shortDescription><![CDATA[%s]]></shortDescription>\n", $shortDescrip);
			print FH sprintf("\t\t<longDescription><![CDATA[%s]]></longDescription>\n", $longDescrip);
			print FH sprintf("\t\t<options>\n");
			print FH sprintf("\t\t\t<option name=\"seed\" value=\"%d\"/>\n", $seedOffset + $iSimGlobal);
			print FH sprintf("\t\t\t<option name=\"lengthSec\" value=\"%d\"/>\n", $lengthSec);
			print FH sprintf("\t\t</options>\n");
			print FH sprintf("\t</condition>\n");
			print FH "</conditions>\n";
			close(FH);
			
			my $jobFileName = sprintf("%s/%s/%d/job.generationSimulation.sh", $outDir, $conditionSetTimeStamp, $iSimGlobal);
			open(FH, '>', $jobFileName) or die $!;
			$template->param(n => $iSimGlobal);
			$template->param(nChild1 => $iSimGlobalOff + $nGenZero * (2 ** $iGen) + 2 * $iSim + 1);
			$template->param(nChild2 => $iSimGlobalOff + $nGenZero * (2 ** $iGen) + 2 * $iSim + 2);		
			$template->param(hasParentJob => $iGen > $iGenMin);
			$template->param(hasInitialConditions => $iGen > 0);
			if ($iGen <= $iGenMin){
				$template->param(afterany => 0);
			}else{
				$template->param(afterany => $prevGenFirstSimIdx + floor($iSim / 2));
			}
			
			print FH $template->output;
			close(FH);
			`chmod 775 $jobFileName`;

			if ($iSim < $maxSimPerGeneration){
				$nJobs++;
				$submitJobs .= "sudo qsub $jobFileName; ";
			}
			
			if ($iSim == $nGenZero * (2 ** $iGen) - 1){
				`chmod -R 775 $outDir/$conditionSetTimeStamp`;
				`sudo chown -R $linuxUser:$linuxUser $outDir/$conditionSetTimeStamp`;
				`$submitJobs`;
				
				my $tmp = `qstat | tail -n 1`;
				$tmp =~ /^(\d+)/;
				$prevGenFirstSimIdx = $1 - min($maxSimPerGeneration, $nGenZero * (2 ** $iGen)) + 1;
				
				$submitJobs = '';
			}
		}
	}
	
	$iSimGlobalOff += $nGenZero * (2 ** $iGen);
}

#get first job id
my $simulationId = `qstat | tail -n 1`;
$simulationId =~ /^(\d+)/;
my $simulationIdx = $1 - $nJobs + 1;

#reindexing job
$submitJobs = '';
$template = HTML::Template->new(filename => 'job.reindexing.sh.tmpl');
$template->param(conditionSetTimeStamp => $conditionSetTimeStamp);
$template->param(linuxRunUser => $linuxRunUser);
$template->param(emailAddress => $emailAddress);
$template->param(outDir => $outDir);
$template->param(storageServer => $storageServer);
$template->param(pathToRunTime => $pathToRunTime);
$template->param(nodeTmpDir => $nodeTmpDir);

my $iSimGlobalMin = 0;
for (my $iGen = 0; $iGen < $iGenMin; $iGen++){
	$iSimGlobalMin += $nGenZero * (2 ** $iGen);
}

my $afterany = $simulationIdx - 1;

my $N = $nGenZero * (2 ** $nGenerations - 1);
if ($iGenMin > 0){
	$N -= $nGenZero * (2 ** ($iGenMin - 1));
}
for (my $n = 1; $n <= $N; $n++){
	my $iSimGlobal = $iSimGlobalMin + $n;	
		
	my $dirName = sprintf("%s/%s/%d", $outDir, $conditionSetTimeStamp, $iSimGlobal);
	open(FH, '<', "$dirName/generation.cell.index") or die $!;
	my @tmp = <FH>;
	my $iSim = @tmp[0] + 0;
	close(FH);
	
	if ($iSim < $maxSimPerGeneration){
		$afterany++;
			
		my $jobFileName2 = sprintf("%s/%s/%d/job.reindexing.sh", $outDir, $conditionSetTimeStamp, $iSimGlobal);
		open(FH, '>', $jobFileName2) or die $!;
		$template->param(n => $iSimGlobal);
		$template->param(afterany => $afterany);
		print FH $template->output;
		close(FH);
		`chmod 775 $jobFileName2`;
		
		$submitJobs .= "sudo qsub $jobFileName2; ";
		
		#record pbs ids
		open(FH, '>', "$outDir/$conditionSetTimeStamp/$iSimGlobal/simulation.pbsid") or die $!;
		print FH "$afterany\n";
		close(FH);
			
		open(FH, '>', "$outDir/$conditionSetTimeStamp/$iSimGlobal/reindexing.pbsid") or die $!;
		print FH ($afterany + $nJobs)."\n";
		close(FH);
	}
}

#set permissions and run jobs
`chmod -R 775 $outDir/$conditionSetTimeStamp`;
`sudo chown -R $linuxUser:$linuxUser $outDir/$conditionSetTimeStamp`;
`$submitJobs`;

#print status message with total number of jobs submitted
print "Simulation set queued with $nJobs simulations.\n";
